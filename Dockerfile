FROM ruby:3.3.5
ENV DENO_INSTALL="/root/.deno"
ENV PATH="$DENO_INSTALL/bin:$PATH"
RUN curl -fsSL https://deno.land/install.sh | sh && deno install --global --allow-net https://deno.land/x/nosdump@0.4.5/main.ts
COPY ["Gemfile", "Gemfile.lock", "/"]
RUN bundle config without development && bundle
COPY ["app.rb", "/nosdump-and-store.rb"]
CMD ["ruby", "nosdump-and-store.rb"]
