module Rake
  class RagelExtensionTask < ExtensionTask
    
    attr_accessor :source_files
    attr_accessor :rl_dir
    
    def init(name = nil, gem_spec = nil)
      super
      
      @lang     = "c"
      @rl_dir = "ragel"
      define_tasks
    end
    
    def source_files
      @source_files = ["#{@ext_dir}/redcloth_scan.c", "#{@ext_dir}/redcloth_inline.c", "#{@ext_dir}/redcloth_attributes.c"]
      
      # @source_files ||= FileList["#{@ext_dir}/#{@source_pattern}"]
    end
    
    def define_tasks
      %w(scan inline attributes).each do |machine|
        file target(machine) => [*ragel_dependencies(machine)] do
          mkdir_p(File.dirname(target(machine))) unless File.directory?(File.dirname(target(machine)))
          ensure_ragel_version(target(machine)) do
            sh "ragel #{flags} #{lang_ragel(machine)} -o #{target(machine)}"
          end
        end
        
        file extconf => [target(machine)]
      end
    end

    def target(machine)
      {
        'scan' => {
          'c'    => "#{@ext_dir}/redcloth_scan.c",
          'java' => "#{@ext_dir}/RedclothScanService.java",
          'rb'   => "#{@ext_dir}/redcloth_scan.rb"
        },
        'inline' => {
          'c'    => "#{@ext_dir}/redcloth_inline.c",
          'java' => "#{@ext_dir}/RedclothInline.java",
          'rb'   => "#{@ext_dir}/redcloth_inline.rb"
        },
        'attributes' => {
          'c'    => "#{@ext_dir}/redcloth_attributes.c",
          'java' => "#{@ext_dir}/RedclothAttributes.java",
          'rb'   => "#{@ext_dir}/redcloth_attributes.rb"
        }
      }[machine][@lang]
    end

    def lang_ragel(machine)
      "#{@rl_dir}/redcloth_#{machine}.#{@lang}.rl"
    end

    def ragel_dependencies(machine)
      [lang_ragel(machine),   "#{@rl_dir}/redcloth_#{machine}.rl", "#{@rl_dir}/redcloth_common.#{@lang}.rl",   "#{@rl_dir}/redcloth_common.rl"] + (@lang == 'c' ? ["#{@ext_dir}/redcloth.h"] : [])
      # FIXME: merge that header file into other places so it can be eliminated?
    end

    def flags
      # FIXME: reinstate @code_style being passed from optimize rake task?
      code_style_flag = preferred_code_style ? " -" + preferred_code_style : ""
      "-#{host_language}#{code_style_flag}"
    end

    def host_language
      {
        'c'      => 'C',
        'java'   => 'J',
        'rb'     => 'R'
      }[@lang]
    end

    def preferred_code_style
      {
        'c'      => 'T0',
        'java'   => nil,
        'rb'     => 'F1'
      }[@lang]
    end

    def ensure_ragel_version(name)
      @ragel_v ||= `ragel -v`[/(version )(\S*)/,2].split('.').map{|s| s.to_i}
      if @ragel_v[0] > 6 || (@ragel_v[0] == 6 && @ragel_v[1] >= 3)
        yield
      else
        STDERR.puts "Ragel 6.3 or greater is required to generate #{name}."
        exit(1)
      end
    end
    
  end
end