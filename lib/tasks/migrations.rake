#
# CouchRest Migration Rake Tasks
#
# Use at own risk! These are not tested yet!
#
namespace :couchrest do

  desc "Migrate all the design docs found in each model"
  task :migrate => :environment do
    CouchRest::Model::Migrate.load_all_models
    CouchRest::Model::Migrate.all_models
  end

  desc "Migrate all the design docs "
  task :migrate_with_proxies => :environment do
    CouchRest::Model::Migrate.load_all_models
    CouchRest::Model::Migrate.all_models_and_proxies
  end


end
