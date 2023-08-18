FROM ruby:3.2.2
ENV DENO_INSTALL="/root/.deno"
ENV PATH="$DENO_INSTALL/bin:$PATH"
RUN curl -fsSL https://deno.land/x/install/install.sh | sh && deno install --allow-net https://deno.land/x/nosdump@0.4.0/main.ts
COPY ["Gemfile", "Gemfile.lock", "app.rb", "/"]
RUN bundle
CMD ruby /app.rb
