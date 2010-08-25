module Fabulator
  module WLC
    module Actions
      class MakeAssetAvailable < Fabulator::Action
        namespace WLC_NS

        attribute :tag, :static => true, :default => nil

        has_select

        def run(context, autovivify = false)
          @context.with(context) do |ctx|
            assets = @select.run(ctx, autovivify)
            assets.each do |asset|
              next if asset.vtype.nil?
              next unless asset.vtype.join('') == [ ASSETS_NS, 'asset' ].join('')
              next unless asset.value =~ %r{^TempFile\s+(\d+)$}
              # we want to convert TempFile to Upload
              file_id = $1.to_i
              file = (TempFile.find(file_id) rescue nil)
              next if file.nil?

              tag = @tag.nil? ? asset.path.gsub('^/','') : @tag

              upload = Upload.find(:first, :conditions => [
                'holder_type = ? AND holder_id = ? AND tag = ?',
                file.holder.class.name, file.holder.id, tag
              ])

              if upload.nil?
                upload = Upload.new
                upload.holder = file.holder
                upload.tag = tag
              end
              upload.user = file.holder.user
              upload.upload = file
              upload.save
              asset.value = "#{upload.class.name} #{upload.id}"
              asset.set_attribute('download-name', upload.download_name)
              asset.set_attribute('download-url', '/uploads/' + upload.id.to_s)
              file.destroy
            end
          end
        end
      end
    end
  end
end
