require 'rubygems'
require 'sinatra'
require 'data_mapper'


### DB SETUP ###

DataMapper::Database.setup({
  :adapter  => 'sqlite3',
  :host     => 'localhost',
  :username => '',
  :password => '',
  :database => 'db/my_way_development'
})


$LOG = Logger.new('log/my_way.log')
$LOG.level = Logger::INFO

### MODELS ###

class Article < DataMapper::Base
  has_many :comments
  has_many :tags
  
  property :id,         :integer, :key => true
  property :title,      :text
  property :text,       :text
  property :posted_by,  :string
  property :permalink,  :text
  property :created_at, :datetime
  property :updated_at, :datetime
  
  attr_accessor :validation_errors
  
  def initialize(attributes = nil)
    @validation_errors = []
    super(attributes)
  end

  def valid?
    unless self.title and self.title.strip.length != 0 
      self.validation_errors << "Title can not be blank!"
    end
    unless self.text and self.text.strip.length != 0 
      self.validation_errors << "Text can not be blank!"
    end
    unless self.posted_by and self.posted_by.strip.length != 0
      self.validation_errors << "Written by can not be blank!"
    end
    
    if self.validation_errors.length != 0
      false
    else
      true
    end
  end
  
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
  
class Comment < DataMapper::Base
  belongs_to :article
  property :posted_by, :string
  property :email,     :string
  property :url,       :string
  property :body,      :text
end

class Tag < DataMapper::Base
  has_many :articles
  property :name, :text
  property :count, :integer
  
  class << self
    def build(options)
      name = options[:name]
      article = options[:article]
      
      $LOG.info("Class Tag.build() name => #{name}")   
      $LOG.info("Class Tag.build() article => #{article.to_s}")  
      
      # article id & tag id association not geting set??
      
      tag = Tag.find(:first, :name => name)
      if tag
        tag.count += 1
        article.tags << tag
      else
          article.tags.create(:name => name, :count => 1)
      end
    
    end
  end
end

database.table_exists?(Article) or database.save(Article)
database.table_exists?(Comment) or database.save(Comment)
database.table_exists?(Tag) or database.save(Tag)

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
  
  $LOG.info("POST 'articles/create' 
            params[:article_tags] => #{@article.title}")
          
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








