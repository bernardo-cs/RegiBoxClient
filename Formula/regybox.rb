class Regybox < Formula
  desc "Unofficial command-line client for RegiBox gym class bookings"
  homepage "https://github.com/bernardo-cs/RegiBoxClient"
  url "https://github.com/bernardo-cs/RegiBoxClient/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "3dc33ce06a67f4af710b04606d193f5d3953f43434977d326cc8104deaa070b3"
  license "MIT"
  head "https://github.com/bernardo-cs/RegiBoxClient.git", branch: "main"

  depends_on xcode: ["15.0", :build]
  depends_on :macos

  def install
    system "swift", "build", "-c", "release", "--disable-sandbox"
    bin.install ".build/release/regybox"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/regybox --version")
    assert_match "list-boxes", shell_output("#{bin}/regybox --help")
  end
end
