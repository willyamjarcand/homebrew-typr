class Typr < Formula
  desc 'Terminal-based typing speed test with real-time feedback'
  homepage 'https://github.com/willyamjarcand/typr'
  url 'https://github.com/willyamjarcand/typr/archive/v0.1.0.tar.gz'
  sha256 '0019dfc4b32d63c1392aa264aed2253c1e0c2fb09216f8e2cc269bbfb8bb49b5'
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
