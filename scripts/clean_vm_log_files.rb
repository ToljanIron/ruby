
module LogDelete
  require './Utils/util'

  def self.deleter(path)
    Dir.glob("#{path}*.log") do |file|
      File.delete(file)
    end
    Dir.glob("#{path}*.log.*") do |file|
      File.delete(file)
      File.open(file, 'w') { |f| f.write('') }
      LoggerUtil.log('info', file)
    end
  end

  def self.log_files_deleter
    ARGV.map { |path| deleter(path)  unless Dir[path].empty? }
  end
end
LoggerUtil.log('info', 'Collector starting cleaning VMs log files')
LogDelete.log_files_deleter
LoggerUtil.log('info', 'Collector finished cleaning VMs log files')
