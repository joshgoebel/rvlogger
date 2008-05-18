class CachedFile < File

  class << self
    attr_accessor :flush, :max_file_handles, :files
  end

  @max_file_handles=100
  @close_at_once=5
  @flush=true
  @files={}

  attr_accessor :last_write

  def self.close_all
    @files.values { | file | file.close }
  end

  def self.maintain_limits
    return if @max_file_handles>@files.size
    files=@files.values.sort { |a,b| a.last_write <=> b.last_write }
    files[0..(@close_at_once-1)].each do | file |
      file.close
    end
  end
  
  def self.max_file_handles=(handles)
    @max_file_handles=(handles<20 ? 20 : handles)
    @close_at_once=handles/20
  end

  # write to file, but also update last written
  def write(*args)
    # incase another objects still has this file handle
    # even after we've closed it
    self.reopen! if self.closed?
    super 
    self.last_write=Time.now
    self.flush if self.class.flush
#    Kernel::puts self.class.files.size.to_s + " cached files open :"
#    Kernel::puts(self.class.files.map { |key, value| key }.join "\n")
  end

  def reopen!
    self.reopen self.path
    self.class.maintain_limits
    self.class.files[self.path]=self
  end

  # close file and remove from cache
  def close
    self.class.files.delete self.path
#    Kernel::puts "closing #{self.path}"
    super
#    Kernel::puts self.class.files.size
#    Kernel::puts self.class.files.each { |key |}
  end

  def self.open(filename, mode=nil)
    # return the file if it's already in our cache
#    puts "open:" + @files.each { |key, value| key }.inspect
    return @files[filename] if @files[filename]
#    puts "opening #{filename}"
    maintain_limits
    @files[filename]=super filename, mode
  end

end