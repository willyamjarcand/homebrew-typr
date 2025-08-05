class Typr < Formula
  desc "Terminal-based typing speed test with real-time feedback"
  homepage "https://github.com/willyamarcand/typr"
  url "https://github.com/willyamarcand/typr/archive/v0.1.0.tar.gz"
  sha256 "YOUR_SHA256_HERE" # Generate this when you create the release
  license "MIT"

  depends_on "ruby"

  def install
    libexec.install Dir["*"]
    (bin/"typr").write <<~EOS
      #!/bin/bash
      exec "#{Formula["ruby"].opt_bin}/ruby" "#{libexec}/typr.rb" "$@"
    EOS
    chmod 0755, bin/"typr"
  end

  test do
    # Test that the command exists and responds
    assert_match "Type the text below", shell_output("echo | timeout 1 #{bin}/typr || true")
  end
end