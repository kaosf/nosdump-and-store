is_development = ENV.fetch("IS_DEVELOPMENT") { "" } == "1"

unless is_development
  $stdout = IO.new(IO.sysopen("/proc/1/fd/1", "w"), "w")
  $stdout.sync = true
end
require "active_record"
I18n.enforce_available_locales = false
require "uri"
ActiveRecord::Base.establish_connection ENV["DATABASE_URL"]
# This snippet ref. https://gist.github.com/kaosf/f4451b36e55012e6b7d1781e6a88df6a

require "logger"
LOGGER = Logger.new $stdout

require "activerecord-import"

class NostrEvent < ActiveRecord::Base
  validates :id, presence: true, uniqueness: true
  validates :kind, presence: true
  validates :created_at, presence: true
  validates :body, presence: true
end

AUTHORS =
  if is_development
    %w[
      npub1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    ]
  else
    ENV["NOSDUMP_AUTHORS"].split(",")
  end

RELAYS =
  if is_development
    %w[
      wss://nostr.example.com
    ]
  else
    ENV["NOSDUMP_RELAYS"].split(",")
  end

LOGGER.info "authors: #{AUTHORS}"
LOGGER.info "relays: #{RELAYS}"

require "digest"
require "schnorr"

def serialize event
  JSON.generate([0, event["pubkey"], event["created_at"], event["kind"], event["tags"], event["content"]])
end

def validate_event(event)
  if Digest::SHA256.hexdigest(serialize(event)) != event["id"]
    LOGGER.error "Invalid ID; id: #{event["id"]}"
    return false
  end

  public_key = [event["pubkey"]].pack("H*")
  signature = [event["sig"]].pack("H*")
  message = [event["id"]].pack("H*")
  valid = Schnorr.valid_sig?(message, public_key, signature)
  LOGGER.error "Invalid signature; sig: #{event["sig"]}, id: #{event["id"]}" unless valid
  valid
end
# This validation snippet ref. https://github.com/kaosf/nostr-backup/blob/a3afebf2b20805f3e2d5492e8c42bc76c2ecc01f/validation/run.rb

require "open3"

def build_nostr_event line
  body = JSON.parse line
  raise StandardError, "Invalid event" unless validate_event body

  id = body["id"]
  kind = body["kind"]
  created_at = body["created_at"]
  NostrEvent.new(id:, kind:, created_at:, body:)
end

def fetch_events since
  nostr_events = []
  Open3.popen3("nosdump", "--since", since, "--authors", *AUTHORS, *RELAYS) do |stdin, stdout, _, _|
    stdin.close
    stdout.each_line do |line|
      nostr_events << build_nostr_event(line.chomp)
    rescue => e
      LOGGER.error e
    end
  end
  nostr_events
end

SINCE_MARGIN_SECONDS = ENV.fetch("SINCE_MARGIN_SECONDS") { "2592000" }.to_i
SLEEP_SECONDS = ENV.fetch("SLEEP_SECONDS") { "3600" }.to_i

loop do
  LOGGER.info "Start"
  since = "#{(Time.now - SINCE_MARGIN_SECONDS).to_i}"
  LOGGER.info "Run nosdump; since: #{since}"
  nostr_events = fetch_events since
  LOGGER.info "Done fetch; Number of events: #{nostr_events.size}"
  begin
    result = NostrEvent.import nostr_events, validate: true, validate_uniqueness: true
    LOGGER.info "Done store; num_inserts: #{result.num_inserts}"
  rescue ActiveRecord::Error => e
    LOGGER.error e
    exit 1
  rescue => e
    LOGGER.error e
  end
  LOGGER.info "Sleep #{SLEEP_SECONDS} seconds"
  sleep SLEEP_SECONDS
end
