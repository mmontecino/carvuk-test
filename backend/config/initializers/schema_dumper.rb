# Supabase preinstalls extensions in its own `extensions` and `vault` schemas
# (pg_stat_statements, supabase_vault, ...). The app doesn't use them, and
# keeping them in db/schema.rb would break loading it on a plain Postgres
# (the local test database).
module SkipSupabaseExtensions
  SUPABASE_SCHEMAS = %w[extensions vault].freeze

  private
    def extensions(stream)
      extensions = @connection.extensions.reject { |name| name.split(".").first.in?(SUPABASE_SCHEMAS) }
      if extensions.any?
        stream.puts "  # These are extensions that must be enabled in order to support this database"
        extensions.sort.each { |extension| stream.puts "  enable_extension #{extension.inspect}" }
        stream.puts
      end
    end
end

ActiveSupport.on_load(:active_record_postgresqladapter) do
  ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaDumper.prepend(SkipSupabaseExtensions)
end
