class Typr < Formula
  desc 'Terminal-based typing speed test with real-time feedback'
  homepage 'https://github.com/willyamjarcand/homebrew-typr'
  url 'https://github.com/willyamjarcand/homebrew-typr/archive/v0.3.0.tar.gz'
  sha256 'e904c0caf9fd3a55eb128b215df8c3ad4c32c79ef9be41de836d420552cc86a3'
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
