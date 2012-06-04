class Article < CouchRest::Model::Base
  use_database DB
  unique_id :slug

  design do
    view :by_date, :descending => true
    view :by_user_id_and_date

    view :by_tags,
      :map => 
        "function(doc) {
          if (doc['#{model.model_type_key}'] == 'Article' && doc.tags) {
            doc.tags.forEach(function(tag){
              emit(tag, 1);
            });
          }
        }",
      :reduce => 
        "function(keys, values, rereduce) {
          return sum(values);
        }"

  end

  property :date, Date
  property :slug, :read_only => true
  property :user_id
  property :title
  property :tags, [String]

  timestamps!

  before_save :generate_slug_from_title

  def generate_slug_from_title
    self['slug'] = title.downcase.gsub(/[^a-z0-9]/,'-').squeeze('-').gsub(/^\-|\-$/,'') if new?
  end
end
