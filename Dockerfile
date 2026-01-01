FROM ruby:4.0.0
ENV DENO_INSTALL="/root/.deno"
ENV PATH="$DENO_INSTALL/bin:$PATH"
RUN curl -fsSL https://deno.land/install.sh | sh && deno install -g -A "jsr:@jiftechnify/nosdump@0.7.1"
COPY ["Gemfile", "Gemfile.lock", "/"]
RUN bundle config set without development && bundle install
COPY ["app.rb", "/nosdump-and-store.rb"]
CMD ["ruby", "nosdump-and-store.rb"]
