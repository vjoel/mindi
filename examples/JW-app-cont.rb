require 'mindi'

# Jim Weirich's example, in MinDI. From Jim Weirich's article at 
# http://onestepback.org/index.cgi/Tech/Ruby/DependencyInjectionInRuby.rdoc).

# Note that this code does not run because it depends on undefined classes.

class JWApplicationContainer
  include MinDI::BasicContainer

  logfilename { "logfile.log" }
  db_user     { "jim" }
  db_password { "secret" }
  dbi_string  { "DBI:Pg:example_data" }

  app {
    app = WebApp.new(quotes, authenticator, database)
    app.logger = logger
    app.set_error_handler error_handler
    app
  }

  quotes        { StockQuotes.new(error_handler, logger) }
  authenticator { Authenticator.new(database, logger, error_handler) }
  database      { DBI.connect(dbi_string, db_user, db_password) }

  logger { Logger.new(logfilename) }
  error_handler {
    errh = ErrorHandler.new
    errh.logger = logger
    errh
  }
end

def create_application
  JWApplicationContainer.new.app
end
