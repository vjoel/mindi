require 'mindi'

# Jim Weirich's example, in MinDI. From Jim Weirich's article at 
# http://onestepback.org/index.cgi/Tech/Ruby/DependencyInjectionInRuby.rdoc).

# Note that this code does not run because it depends on undefined classes.

# For the "injected" version, we assume that classes like WebApp, StockQuotes,
# and so on are written to refer directly to "error_handler", "logger", etc.
# The effect of injection is that these references will resolve to the
# error_handler, logger, etc. that belong to the same container.
#
# In the case of DBI and Logger, which are pre-existing classes, we use the
# more traditional approach of using argument lists to pass in references to
# the services that they need from the container.

class JWApplicationContainer
  include MinDI::InjectableContainer

  logfilename { "logfile.log" }
  db_user     { "jim" }
  db_password { "secret" }
  dbi_string  { "DBI:Pg:example_data" }

  app           { WebApp.new }
  quotes        { StockQuotes.new }
  authenticator { Authenticator.new }
  database      { DBI.connect(dbi_string, db_user, db_password) }

  logger        { Logger.new }
  error_handler { ErrorHandler.new }
end

def create_application
  JWApplicationContainer.new.app
end
