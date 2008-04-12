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

### MODELS ###

class Article < DataMapper::Base
  has_many :comments
  has_many :tags
  property :title, :text
  property :text, :text
  property :posted_by, :string
  property :permalink, :text
  property :created_at, :datetime
  property :updated_at, :datetime
  
  def short_text
    text_len = 50
    if self.text.length > text_len
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
  property :email, :string
  property :url, :string
  property :body, :text
end

class Tag < DataMapper::Base
  has_many :articles
  property :name, :text
  property :count, :integer
end

database.table_exists?(Article) or database.save(Article)
database.table_exists?(Comment) or database.save(Comment)
database.table_exists?(Tag) or database.save(Tag)

### CONTROLLER ACTIONS

get '/style.css' do
  header 'Content-Type' => 'text/css; charset=utf-8'
  sass :style
end

## LIST ARTICLES ##
get '/articles' do
  
  @articles = Article.all :limit => 10, 
                          :order => 'created_at desc'                       
  view :articles
end


## VIEW ARTICLE ##
get '/article/:permalink' do
  @article = Article.find :first,
                          :permalink => params[:permalink] 
  view :article
end


## NEW ARTICLE ##
get '/articles/new' do
  view :article_new
end

post '/articles/create' do

  @article = Article.new :title     => params[:article_title],
                         :text      => params[:article_text],
                         :posted_by => params[:article_posted_by],
                         :permalink => create_permalink(params[:article_title])
  if @article.save 
    redirect "/article/#{@article.permalink}"
  else
    redirect "/articles"
  end
  
end


## EDIT ARTICLE ##
get '/article/edit/:permalink' do
  @article = Article.find :first,
                          :permalink => params[:permalink] 
  view :article_edit
end

post '/article/update/:permalink' do
  @article = Article.find :first,
                          :permalink => params[:permalink]
                          
  
end

private

def view(view)
  haml view
  #erb view
end

def create_permalink(string)
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








