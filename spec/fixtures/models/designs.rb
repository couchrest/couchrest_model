
class DesignModel < CouchRest::Model::Base
  use_database DB
  property :name
end

class DesignsModel < CouchRest::Model::Base
  use_database DB
  property :name
end


class DesignsNoAutoUpdate < CouchRest::Model::Base
  use_database DB
  property :title, String
  design do
    disable_auto_update
    view :by_title_fail, :by => ['title']
    view :by_title, :reduce => true
  end
end

