require 'spec_helper'

describe ProcessNewArticlesJob do
  before(:each) do
    Article.all.each do |a|
      a.delete
    end

    Delayed::Job.all.each do |job|
      job.delete
    end

    @config = RSS_CONFIG
    @feeds = @config['rss_feeds']
  end

  it 'should process simple unauthenticated rss' do
    enqueue_process(@feeds[0], @config['settings'])
    work_off

    item = Article.where(:link => 'http://labs.silverorange.com/archives/2003/june/canyousaythat')
    item.any?.should be(true)
    item.size.should be(1)

    # ensure all the properties are on the article
    article = item.first
    article.description.should_not be(nil)
    article.description.should_not be ""

    article.title.should_not be(nil)
    article.link.should match 'http://labs.silverorange.com/archives/2003/june/canyousaythat'
    article.guid.should_not be(nil)
    article.comments.should_not be(nil)

    Article.all.size.should be(6)
  end

  it 'should process rss over https' do
    enqueue_process(@feeds[1], @config['settings'])
    work_off

    Article.all.size.should be(6)
  end

  it 'should process authenticated rss over http' do
    enqueue_process(@feeds[2], @config['settings'])
    work_off

    Article.all.size.should be(6)

    item = Article.where(:link => 'http://labs.silverorange.com/archives/2003/june/introducingthe').first
    item.title.should match 'Introducing the silverorange Labs weblog'
  end

  it 'should process authenticated rss over https' do
    enqueue_process(@feeds[3], @config['settings'])
    work_off

    Article.all.size.should be(6)
  end

  it 'should not process incorrect auth over https' do
    enqueue_process(@feeds[4], @config['settings'])
    work_off

    Article.all.size.should be(0)
  end

  it 'should not process authenticated ssl over http' do
    enqueue_process(@feeds[5], @config['settings'])
    work_off

    Article.all.size.should be(0)
  end

end

private

def enqueue_process(rss_feed, settings)
  Delayed::Job.enqueue ProcessNewArticlesJob.new(rss_feed, settings)
end

def work_off
  Delayed::Worker.new.work_off
end