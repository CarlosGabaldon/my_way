require 'rubygems'
require 'sinatra'
require 'pathname'

# Edge
require Pathname(__FILE__).dirname.expand_path + '../dm-core/lib/data_mapper'
require Pathname(__FILE__).dirname.expand_path + '../dm-core/lib/data_mapper/auto_migrations'

#GEM (0.3.1)
#require 'data_mapper'


### DB SETUP ###

DB_PATH = 'db/my_way_development'

DataMapper.setup(:sqlite3, "sqlite3://#{DB_PATH}")

$LOG = Logger.new('log/my_way.log')
$LOG.level = Logger::INFO

### MODELS ###

class Article
  
  include DataMapper::Resource
  
  many_to_many :comments
  many_to_many :tags
  
  property :id, Fixnum, :serial => true
  property :title, String, :nullable => false
  property :text, DataMapper::Types::Text, :nullable => false
  property :posted_by, String, :nullable => false
  property :permalink, String
  property :created_at, DateTime
  property :updated_at, DateTime


  def short_text
    text_len = 50
    if self.text and self.text.length > text_len
      "#{self.text[0, text_len]}.. <a href='/article/#{self.permalink}'> more >> </a>"
    else
      self.text
    end
  end
  
  def written_by
    "Written by: #{self.posted_by}"
  end
  
  def written_on
    self.created_at.strftime("Written on: %m/%d/%Y")
  end

  
end
  
class Comment
  
  include DataMapper::Resource
  
  belongs_to :article
  
  property :id, Fixnum, :serial => true
  property :posted_by, String
  property :email, String
  property :url, String
  property :body, DataMapper::Types::Text
end

class Tag 
  
  include DataMapper::Resource
  
  many_to_many :articles
  
  property :id, Fixnum, :serial => true
  property :name, DataMapper::Types::Text
  property :count, Fixnum, :default  => 0
  
  class << self
    def build(options)
      name = options[:name]
      article = options[:article]
      
      $LOG.info("Class Tag.build() name => #{name}")   
      $LOG.info("Class Tag.build() article => #{article.to_s}")  
      
      tag = Tag.find_or_create(:name => name)
      $LOG.info("Class Tag.build() tag => #{tag.to_s}") if tag
      
      article.tags << tag
      
 #     if tag
 #       tag.count += 1
 #     end
    
    end
  end
end

DataMapper::AutoMigrations.auto_migrate!

### CONTROLLER ACTIONS

get '/application.css' do
  header 'Content-Type' => 'text/css; charset=utf-8'
  sass :style
end

## LIST ARTICLES ##
get '/articles' do
  
  @articles = Article.all(:limit => 10, 
                          :order => 'created_at desc')  
                          
  $LOG.info("GET '/articles' @articles.length => #{@articles.length.to_s}")     
                 
  view :articles
end


## VIEW ARTICLE ##
get '/article/:permalink' do
  @article = Article.find(:first,
                          :permalink => params[:permalink])
                          
  $LOG.info("GET '/article/#{params[:permallink]}' @article.title => #{@article.title}")
  
  view :article
end


## NEW ARTICLE ##
get '/articles/new' do
  view :article_new
end

post '/articles/create' do

  @article = Article.new(:title     => params[:article_title],
                         :text      => params[:article_text],
                         :posted_by => params[:article_posted_by],
                         :permalink => clean(params[:article_title]))
       
  tags_param = params[:article_tags]    
  
  $LOG.info("POST 'articles/create' params[:article_title] => #{@article.title}")
          
  if tags_param
    tags_param.each(",") do |tag_param| 
      Tag.build(:article => @article, :name => clean(tag_param))
    end
  end
  
  if @article.valid?
    if @article.save 
      redirect "/article/#{@article.permalink}"
    else
      redirect "/articles"
    end
  else
    view :article_new 
  end
  
end


## EDIT ARTICLE ##
get '/article/edit/:permalink' do
  @article = Article.find(:first,
                          :permalink => params[:permalink])
                          
  $LOG.info("GET '/article/edit#{params[:permallink]}' @article.title => #{@article.title}")
  
  view :article_edit
end

post '/article/update/:permalink' do
  @article = Article.find(:first,
                          :permalink => params[:permalink])
  if @article
    @article.title      = params[:article_title]
    @article.text       = params[:article_text]
    @article.posted_by  = params[:article_posted_by]
    @article.updated_at = Time.now
    
    if @article.save
      redirect "/article/#{@article.permalink}"
    else
      redirect "/articles"
    end
  else
    redirect "/articles"
  end                        
end

helpers do
  def view(view)
    haml view
  end
end




def clean(string)
  string = string.strip
  string = string.tr(' ', '_')
  string = string.tr("'", "")
  string = string.tr("$", "")
  string = string.tr("&", "")
  string = string.tr("<", "")
  string = string.tr(">", "")
  string = string.tr("*", "")
  string = string.tr("@", "")
  string = string.tr(".", "")
  string = string.tr(":", "")
  string = string.tr("|", "")
  string = string.tr("~", "")
  string = string.tr("`", "")
  string = string.tr("(", "")
  string = string.tr(")", "")
  string = string.tr("%", "")
  string = string.tr("#", "")
  string = string.tr("^", "")
  string = string.tr("?", "")
  string = string.tr("/", "")
  string = string.tr("{", "")
  string = string.tr("}", "")
  string = string.tr(",", "")
  string = string.tr(";", "")
  string = string.tr("!", "")
  string = string.tr("+", "")
  string = string.tr("=", "")
  string = string.tr("-", "_")
end








