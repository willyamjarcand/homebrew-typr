class Typr < Formula
  desc 'Terminal-based typing speed test with real-time feedback'
  homepage 'https://github.com/willyamjarcand/typr'
  url 'https://github.com/willyamjarcand/typr.git', branch: 'main'
  version '0.1.0'
  head 'https://github.com/willyamjarcand/typr.git'
  license 'MIT'

  depends_on 'ruby'

  def install
    libexec.install Dir['*']
    (bin / 'typr').write <<~EOS
      #!/bin/bash
      exec "#{Formula['ruby'].opt_bin}/ruby" "#{libexec}/typr.rb" "$@"
    EOS
    chmod 0o755, bin / 'typr'
  end

  test do
    # Test that the command exists and responds
    assert_match 'Type the text below', shell_output("echo | timeout 1 #{bin}/typr || true")
  end
end
