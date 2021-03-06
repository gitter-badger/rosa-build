namespace :remove_branch do
  desc "Remove branch for group projects"
  task group: :environment do
    branch = ENV['BRANCH']
    group = ENV['GROUP']
    say "START remove branch #{branch} from #{group} group"
    Group.find_by(uname: group).projects.find_each do |p|
      next if p.repo.branches.map(&:name).exclude?(branch)
      say "===== Process #{p.name} project"
      p.repo.git.native(:branch, {}, '-D', branch)
    end
    say 'DONE'
  end

  desc "Remove branch for platform projects"
  task platform: :environment do
    branch = ENV['BRANCH']
    platform = ENV['PLATFORM']
    say "START remove branch #{branch} from #{platform} platform"
    Platform.find_by(name: platform).repositories.each do |r|
      say "=== Process #{r.name} repo"
      r.projects.find_each do |p|
        next if p.repo.branches.map(&:name).exclude?(branch)
        say "===== Process #{p.name} project"
        p.repo.git.native(:branch, {}, '-D', branch)
      end
    end
    say 'DONE'
  end
end
