
namespace :couchrest do

  desc "Migrate all the design docs found in each model"
  task :migrate => :environment do

    callbacks = [ ]
    puts "Finding all CouchRest Models to migrate (excludes proxied models)"
    CouchRest::Model::Base.subclasses.each do |model|
      next unless model.respond_to?(:design_docs)
      next if model.respond_to?(:model_proxy)
      model.design_docs.each do |design|
        print "Migrating #{model.to_s}##{design.method_name}... "
        callback = design.migrate do |result|
          puts "#{result.to_s.gsub(/_/, ' ')}"
        end

        # Is there a callback?
        if callback
          callbacks << {:design => design, :proc => callback}
        end
      end
    end

    callbacks.each do |cb|
      puts "Copying design for #{cb[:design].model}##{cb[:design].method_name}"
      cb[:proc].call
    end

    puts "Couchrest Model migrations finished"
  end

end
