#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Add source/header files to a target in FLEX.xcodeproj, idempotently.
#
# Usage:
#   ruby Scripts/xcode_add_file.rb <TargetName> <file> [<file> ...]
#
# - Paths may be absolute or relative to the repo root.
# - .m/.mm files are added to the target's Compile Sources build phase.
# - .h files are added as references only (so #import resolves in the project).
# - Re-running is safe: files already present are skipped.
#
# Requires the `xcodeproj` gem (ships with CocoaPods).

require 'xcodeproj'

REPO_ROOT = File.expand_path(File.join(__dir__, '..'))
PROJECT_PATH = File.join(REPO_ROOT, 'FLEX.xcodeproj')

target_name = ARGV.shift
abort('Usage: xcode_add_file.rb <TargetName> <file> [<file> ...]') if target_name.nil? || ARGV.empty?

project = Xcodeproj::Project.open(PROJECT_PATH)
target = project.targets.find { |t| t.name == target_name }
abort("Target not found: #{target_name}") if target.nil?

def find_or_make_group(parent, name)
  existing = parent.children.find do |child|
    child.is_a?(Xcodeproj::Project::Object::PBXGroup) && child.display_name == name
  end
  existing || parent.new_group(name)
end

ARGV.each do |arg|
  abs = File.expand_path(arg, REPO_ROOT)
  abort("File does not exist: #{abs}") unless File.exist?(abs)
  rel = abs.sub("#{REPO_ROOT}/", '')

  ref = project.files.find { |f| f.real_path.to_s == abs }
  if ref.nil?
    group = project.main_group
    File.dirname(rel).split('/').each do |part|
      next if part == '.'
      group = find_or_make_group(group, part)
    end
    ref = group.new_reference(abs)
  end

  if %w[.m .mm .c .cpp].include?(File.extname(abs))
    already = target.source_build_phase.files_references.include?(ref)
    target.add_file_references([ref]) unless already
    puts "compile  #{rel} -> #{target.name}"
  else
    puts "ref      #{rel}"
  end
end

project.save
puts 'Saved FLEX.xcodeproj'
