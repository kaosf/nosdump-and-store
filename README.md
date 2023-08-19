# nosdump and store

[Docker Hub](https://hub.docker.com/r/kaosf/nosdump-and-store)

```sql
CREATE DATABASE nosdump_and_store;

\c nosdump_and_store;

CREATE TABLE nostr_events (
    id character varying NOT NULL,
    created_at integer NOT NULL,
    body json NOT NULL
);
ALTER TABLE ONLY nostr_events ADD CONSTRAINT nostr_events_pkey PRIMARY KEY (id);
CREATE INDEX index_nostr_events_on_created_at ON nostr_events USING btree (created_at);
```

```sh
docker run -d \
-e NOSDUMP_AUTHORS=npub1abc...001,npub1def...002 \
-e NOSDUMP_RELAYS=wss://nostr.example.com,wss://another-relay.example.com \
-e DATABASE_URL=postgres://user:pass@host:5432/nosdump_and_store \
kaosf/nosdump-and-store:latest
```

## TODO

- Add index
- Build Docker image
- Timeout for `nosdump` command
- Research `nosdump` command behavior much more
- Validation or verification feature in other gems
- Fix development `AUTHORS` and `RELAYS`
- Test code

## Development

```sh
docker run -d -p 5432:5432 postgres:14.6
psql postgres://postgres:@127.0.0.1:5432/
```

```sql
CREATE DATABASE "nosdump_and_store_development";
```

```sh
psql postgres://postgres:@127.0.0.1:5432/nosdump_and_store_development
```

```sql
CREATE TABLE IF NOT EXISTS "nostr_events" (
  "id" text primary key,
  "created_at" integer not null,
  "body" json not null
);
```

```sh
bundle

# Edit app.rb

DATABASE_URL=postgres://postgres:@127.0.0.1:5432/nosdump_and_store_development \
IS_DEVELOPMENT=1 \
SLEEP_SECONDS=30 \
bundle exec ruby app.rb
```

## License

[MIT](http://opensource.org/licenses/MIT)

Copyright (C) 2023 ka
