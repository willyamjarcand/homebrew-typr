class Typr < Formula
  desc 'Terminal-based typing speed test with real-time feedback'
  homepage 'https://github.com/willyamjarcand/homebrew-typr'
  url 'https://github.com/willyamjarcand/homebrew-typr/archive/v0.4.0.tar.gz'
  sha256 '69e753502d642b5cee7644246b27b551869c514625f33c05b2244b2173fa35c7'
  head 'https://github.com/willyamjarcand/homebrew-typr.git'
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
