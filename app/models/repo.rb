class Repo < ActiveRecord::Base

  def self.add_repo(owner, name, changelog_name)
    r = Repo.find_by(owner: owner, name: name, changelog_name: changelog_name)
    if r.nil?
      Repo.create!({owner: owner, name: name, changelog_name: changelog_name})
    end
  end

  def self.changelog_from_repo(owner, name)
    a = Repo.find_by(owner: owner, name: name)
    if a
      a.changelog_name
    end
  end

end
