
import sys
from pbxproj import XcodeProject

# Path to your Xcode project
project_path = 'VibeEdit.xcodeproj'
project = XcodeProject.load(project_path + '/project.pbxproj')

# Path to the file to add, relative to the project root
file_to_add = sys.argv[1]

# Find the main group (usually the group named after your project)
# The path should be relative to the source root.
main_group = project.get_or_create_group('VibeEdit')

# Add file to the project and the main target
target = project.get_target_by_name('VibeEdit')
if target:
    project.add_file(file_to_add, target=target, parent=main_group)
    project.save()
    print(f"Successfully added {file_to_add} to the project.")
else:
    print(f"Target 'VibeEdit' not found.")

