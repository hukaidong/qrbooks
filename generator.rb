require 'csv'
require 'erb'
require 'tmpdir'
require 'pathname'
require 'parallel'
require 'active_support'


BASICSEQ = File.read('basic.seq')
DVPSEQ = File.read('dvp.seq')

def tr_escape content
  trspec = %w[-]
  content = content.each_char.map do |c|
    if trspec.include?(c)
      "\\" + c
    else
      c
    end
  end.join
end

class ErbReportGenerator_
end

erb = ERB.new(File.read('template.tex.erb'), trim_mode: '<>')
ErbReportGenerator = erb.def_class(ErbReportGenerator_, 'render()')
ErbReportGenerator.class_eval do
  def render_pdf save_path
    Dir.mktmpdir do |dir|

      success = Dir.chdir(dir) do
        File.write('generated.tex', render)
        system('pdflatex --halt-on-error generated.tex', out: File::NULL)
      end

      if success
        FileUtils.mkdir_p('tmp')
        FileUtils.cp_r(dir, 'tmp')
        FileUtils.cp(File.join(dir, 'generated.pdf'), save_path)
      else
        FileUtils.mkdir_p('tmp')
        FileUtils.cp_r(dir, 'tmp')
        system("tail -n 20 tmp/*/generated.log")
        raise "pdflatex failed"
      end

    end
  end

  def qrfill content, is_password: false
    if is_password
      puts content
      "$#{Array.new(6){"\\bullet"}.join}~$ & #{qrescape(content)} & #{qrescape2(content)} "
    else
      "#{tex_escape(content)} & #{qrescape(content)} & #{qrescape2(content)} "
    end
  end

  def tex_escape content
    texchar = %w[# $ % & _ { } ^ ~ \\]
    texchar.map! { |c| Regexp.escape(c) }
    texreg = Regexp.union(*texchar)
    content.gsub!(texreg) { |m| "\\" + m }

    %w[! @ ^ * _ + - = ; : , . / ? ~].each do |q|
      unless content.include?("|")
        return "\\verb" + q + content + q
      end
    end

    raise "cannot escape #{content}"
  end

  def qrescape content
    spechar = %w[# $ & ^ _ ~ % \\ { } ] + [" "]
    content = content.each_char.map do |c|
      if spechar.include?(c)
        "\\" + c
      else
        c
      end
    end.join
    "\\mbox{\\qrcode[height=3cm]{" + content + "}}"
  end

  def qrescape2 content
    content = content.each_char.map do |c|
      if DVPSEQ.include?(c)
        BASICSEQ[DVPSEQ.index(c)]
      else
        c
      end
    end.join

    qrescape(content)
  end
end

#ErbReportGenerator.new.render_pdf('result.pdf')

generator = ErbReportGenerator.new

generator.instance_eval do
  @csv = CSV.read('/home/kaidong/KeePassDatabase.csv')
end

generator.render_pdf('result.pdf')

# vim: set ts=2 sw=2 et:
