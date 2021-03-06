/*
Copyright 2016 Bowler Hat LLC

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
package moonshine;

import java.io.File;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;

import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import com.nextgenactionscript.asconfigc.TopLevelFields;
import com.nextgenactionscript.asconfigc.compiler.CompilerOptions;
import com.nextgenactionscript.vscode.project.IProjectConfigStrategy;
import com.nextgenactionscript.vscode.project.ProjectOptions;

/**
 * Configures a project for Moonshine IDE.
 */
public class MoonshineProjectConfigStrategy implements IProjectConfigStrategy
{
    private ProjectOptions options;
    private boolean changed = true;

    public MoonshineProjectConfigStrategy()
    {
    }

    public boolean getChanged()
    {
        return changed;
    }

    public void setChanged(boolean value)
    {
        changed = value;
    }

    public void setConfigParams(JsonObject params)
    {
        if (options == null)
        {
            options = new ProjectOptions();
        }
        
        String projectType = params.get(TopLevelFields.TYPE).getAsString();

        String config = params.get(TopLevelFields.CONFIG).getAsString();

        JsonArray jsonFiles = params.getAsJsonArray(TopLevelFields.FILES);
        int fileCount = jsonFiles.size();
        String[] files = new String[fileCount];
        for (int i = 0; i < fileCount; i++)
        {
            files[i] = jsonFiles.get(i).getAsString();
        }

        ArrayList<String> targets = null;
        ArrayList<Path> sourcePaths = null;
        ArrayList<String> compilerOptions = new ArrayList<>();

        JsonObject jsonOptions = params.getAsJsonObject(TopLevelFields.COMPILER_OPTIONS);

        if(jsonOptions.has(CompilerOptions.TARGETS))
        {
            JsonArray jsonTargets = jsonOptions.getAsJsonArray(CompilerOptions.TARGETS);
            sourcePaths = new ArrayList<>();
            for (int i = 0, count = jsonTargets.size(); i < count; i++)
            {
                String targetString = jsonTargets.get(i).getAsString();
                targets.add(targetString);
            }
        }

        if(jsonOptions.has(CompilerOptions.SOURCE_PATH))
        {
            JsonArray jsonSourcePath = jsonOptions.getAsJsonArray(CompilerOptions.SOURCE_PATH);
            sourcePaths = new ArrayList<>();
            for (int i = 0, count = jsonSourcePath.size(); i < count; i++)
            {
                String pathString = jsonSourcePath.get(i).getAsString();
                sourcePaths.add(Paths.get(pathString));
            }
        }
        
        String additionalOptions = null;
        if(params.has(TopLevelFields.ADDITIONAL_OPTIONS))
        {
            additionalOptions = params.get(TopLevelFields.ADDITIONAL_OPTIONS).getAsString();
        }
        
        options.type = projectType;
        options.config = config;
        options.files = files;
        options.targets = targets;
        options.sourcePaths = sourcePaths;
        options.compilerOptions = compilerOptions;
        options.additionalOptions = additionalOptions;
    }

    public ProjectOptions getOptions()
    {
        changed = false;
        if (options == null)
        {
            return null;
        }
        return options;
    }
}
