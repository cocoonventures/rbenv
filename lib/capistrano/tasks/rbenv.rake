require "active_support/core_ext/object/blank.rb"

def bundler_loaded?
  Gem::Specification::find_all_by_name('capistrano-bundler').any?
end

SSHKit.config.command_map = Hash.new do |hash, key|
  map_bins = fetch(:rbenv_map_bins)
  if map_bins.present? and map_bins.include?(key.to_s)
    prefix = "RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"
    hash[key] = if bundler_loaded? && key.to_s != "bundle"
      "#{prefix} bundle exec #{key}"
    else
      "#{prefix} #{key}"
    end
  else
    hash[key] = key
  end
end

namespace :deploy do
  before :starting, :hook_rbenv_bins do
    invoke :'rbenv:check'
  end
end

namespace :rbenv do
  task :check do
    on roles(:all) do
      rbenv_ruby = fetch(:rbenv_ruby)
      if rbenv_ruby.nil?
        error "rbenv: rbenv_ruby is not set"
        exit 1
      end

      if test "[ ! -d #{fetch(:rbenv_ruby_dir)} ]"
        error "rbenv: #{rbenv_ruby} is not installed or not found in #{fetch(:rbenv_ruby_dir)}"
        exit 1
      end
    end
  end
end

namespace :load do
  task :defaults do
    set :rbenv_type, :user

    rbenv_path = fetch(:rbenv_custom_path)
    rbenv_path ||= if fetch(:rbenv_type) == :system
      "/usr/local/rbenv"
    else
      "~/.rbenv"
    end
    set :rbenv_path, rbenv_path

    set :rbenv_ruby_dir, "#{rbenv_path}/versions/#{fetch(:rbenv_ruby)}"
    set :rbenv_map_bins, %w{rake gem bundle ruby}
  end
end
