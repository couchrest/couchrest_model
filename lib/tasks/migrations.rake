#
# CouchRest Migration Rake Tasks
#
# See the CouchRest::Model::Utils::Migrate class for more details.
#
namespace :couchrest do

  namespace :designs do

    desc "Migrate all the design docs found in each model"
    task :migrate => :environment do
      CouchRest::Model::Utils::Migrate.load_all_models
      CouchRest::Model::Utils::Migrate.all_models
    end

    desc "Migrate all the design docs found in each model, but do not active the designs"
    task :prepare => :environment do
      CouchRest::Model::Utils::Migrate.load_all_models
      CouchRest::Model::Utils::Migrate.all_models(activate: false)
    end

    desc "Migrate all the design docs "
    task :migrate_with_proxies => :environment do
      CouchRest::Model::Utils::Migrate.load_all_models
      CouchRest::Model::Utils::Migrate.all_models_and_proxies
    end

    desc "Migrate all the design docs "
    task :prepare_with_proxies => :environment do
      CouchRest::Model::Utils::Migrate.load_all_models
      CouchRest::Model::Utils::Migrate.all_models_and_proxies(activate: false)
    end

  end
end
