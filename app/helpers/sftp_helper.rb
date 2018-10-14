require 'net/sftp'
require 'net/ftp'
require './app/helpers/util.rb'

module FTPHelper
  def self.get_log_files(protocol, host, user, password, files_mask, src_dir, dest_dir)
    ftp_copy( host, user, password, files_mask, src_dir, dest_dir) if protocol == 'FTP'
    sftp_copy(host, user, password, files_mask, src_dir, dest_dir) if protocol == 'SFTP'
  end

  def self.ftp_copy(host, user, password, files_mask, src_dir, dest_dir)
    puts "Doing FTP transfer"
    ftp = Net::FTP.new(host)
    ftp.login(user, password)
    ftp.chdir(src_dir) if src_dir != '.'


    masks_arr = masks_string_to_array(files_mask)
    masks_arr.each do |mask|
      ftp.dir(mask) do |ff|
        file_name = ff.split(' ').last
        ftp.gettextfile(file_name, "#{dest_dir}/#{file_name}")
      end
    end


    ftp.close
  end

  def self.sftp_copy(host, user, password, files_mask, src_dir, dest_dir)
    puts "Doing SFTP transfer"
    Net::SFTP.start(host, user, password: password) do |sftp|

      masks_arr = masks_string_to_array(files_mask)
      masks_arr.each do |mask|

        sftp.dir.glob(src_dir, mask) do |entry|
          path = src_dir == '.' ? entry.name : "./#{src_dir}/#{entry.name}"
          sftp.download!(path, "#{dest_dir}/#{entry.name}")
          sftp.remove(path)
        end

      end
    end
  end

  #########################################################################
  # The masks field in the database is expected to be a list of file masks
  #   (like *.log or *.zip) which are delimitted by a semi-colon.
  # The function will return an array of the masks.
  #########################################################################
  def self.masks_string_to_array(masks)
    return '.' if masks.nil?
    return '.' if masks.empty?
    return masks
             .split(';')
             .map { |m| m.strip }
             .select { |m| !m.nil? && !m.empty? }
  end
end

