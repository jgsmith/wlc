class Upload < ActiveRecord::Base
  belongs_to :user
  belongs_to :holder, :polymorphic => true

  def upload=(u)
    @upload = u
    self.size = u.size
    self.content_type = u.content_type
    self.filename = u.original_filename
  end

  # TODO: make the following configurable
  def dir_path
    RAILS_ROOT + '/uploads/' + Digest::MD5.hexdigest(self.id.to_s)[0..1] + '/'
  end

  def can_user_view_upload?(u)
    u == user || holder.can_user_view_upload?(u)
  end

  def extension
    if self.filename =~ /(\.[^.]+)$/
      return $1
    else
      return ''
    end
  end

  def path
    self.dir_path + self.id.to_s + self.extension
  end

  def download_name
    self.holder.download_filename_prefix + '-' + self.id.to_s + self.extension
  end
 
  def after_save
    FileUtils::mkpath self.dir_path
    FileUtils::cp @upload.path, self.path
  end

  def url
    "/uploads/" + self.id.to_s
  end
end
