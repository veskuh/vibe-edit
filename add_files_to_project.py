
from pbxproj import XcodeProject

# Path to your Xcode project
project_path = 'VibeEdit.xcodeproj'
project = XcodeProject.load(project_path + '/project.pbxproj')

# Paths to the files to add, relative to the project root
files_to_add = ['VibeEdit/Prompt.swift', 'VibeEdit/PromptsView.swift']

# Find the main group (usually the group named after your project)
# The path should be relative to the source root.
main_group = project.get_or_create_group('VibeEdit')

# Add files to the project and the main target
target = project.get_target_by_name('VibeEdit')
if target:
    sources_phase = None
    for phase in target.buildPhases:
        if phase.isa == 'PBXSourcesBuildPhase':
            sources_phase = phase
            break

    if sources_phase:
        for file_path in files_to_add:
            file_ref = project.add_file(file_path, parent=main_group)
            if file_ref:
                sources_phase.add_file(file_ref)
        
        # Save the modified project
        project.save()
        print(f"Successfully added {files_to_add} to the project.")
    else:
        print("Sources build phase not found.")
else:
    print(f"Target 'VibeEdit' not found.")

