class User < ActiveRecord::Base
  attr_accessible :email, :handle, :profile_id, :total_downloads

  validates :handle, presence: true
  validates :email, presence: true
  validates :profile_id, presence: true

  def self.fetch_and_save!(profile_id)
    user = User.find_or_initialize_by_profile_id(profile_id)
    user.attributes = Fetcher.get(profile_id)
    user.save!
  end

  class Fetcher
    def self.get(profile_id)
      new.get(profile_id)
    end

    def agent
      @agent ||= Mechanize.new
    end

    def get(profile_id)
      page = agent.get("http://rubygems.org/profiles/#{profile_id}")
      name = page.search("#profile-name").inner_text
      total_downloads = page.search("#downloads_count strong").map(&:inner_text).map{|t| t.gsub(',', "")}.map(&:to_i).max
      encoded_email = page.search('#profile-email a').attr('href').to_s.gsub('mailto:', "")
      email = URI.decode(encoded_email)
      { handle: name, total_downloads: total_downloads, email: email }
    end
  end
end