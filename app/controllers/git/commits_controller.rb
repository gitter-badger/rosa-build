# -*- encoding : utf-8 -*-
class Git::CommitsController < Git::BaseController

  helper_method :split_commits_by_date

  def index
    @branch_name = params[:treeish] || @project.default_branch
    @branch = @project.branch(@branch_name)
    @path = params[:path]

    if @path.present?
      @commits = @git_repository.repo.log(@branch_name, @path)
      @render_paginate = false
    else
      @commits, @page, @last_page = @git_repository.paginate_commits(@branch_name, :page => params[:page])
      @render_paginate = true
    end
  end

  def show
    @commit = @git_repository.commit(params[:id]) # @git_repository.commits(params[:id]).first

    respond_to do |format|
      format.html
      format.diff  { render :text => (@commit.diffs.map{|d| d.diff}.join("\n") rescue ''), :content_type => "text/plain" }
      format.patch { render :text => (@commit.to_patch rescue ''), :content_type => "text/plain" }
    end
  end

  protected

  def split_commits_by_date(commits)
    res = commits.sort{|x, y| y.authored_date <=> x.authored_date}.inject({}) do |h, commit|
      dt = commit.authored_date
      h[dt.year] ||= {}
      h[dt.year][dt.month] ||= {}
      h[dt.year][dt.month][dt.day] ||= []
      h[dt.year][dt.month][dt.day] << commit
      h
    end
    return res
  end

end
