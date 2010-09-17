class Article < CouchRest::Model::Base
  use_database DB
  unique_id :slug
  
  provides_collection :article_details, 'Article', 'by_date', :descending => true, :include_docs => true
  view_by :date, :descending => true
  view_by :user_id, :date
    
  view_by :tags,
    :map => 
      "function(doc) {
        if (doc['#{model_type_key}'] == 'Article' && doc.tags) {
          doc.tags.forEach(function(tag){
            emit(tag, 1);
          });
        }
      }",
    :reduce => 
      "function(keys, values, rereduce) {
        return sum(values);
      }"  

  property :date, Date
  property :slug, :read_only => true
  property :title
  property :tags, [String]

  timestamps!
  
  before_save :generate_slug_from_title
  
  def generate_slug_from_title
    self['slug'] = title.downcase.gsub(/[^a-z0-9]/,'-').squeeze('-').gsub(/^\-|\-$/,'') if new?
  end
end
