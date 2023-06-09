/*
    This file is part of the Surreal distribution.

    https://github.com/senselogic/SURREAL

    Copyright (C) 2017 Eric Pelzer (ecstatic.coder@gmail.com)

    Surreal is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, version 3.

    Surreal is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Surreal.  If not, see <http://www.gnu.org/licenses/>.
*/

// -- IMPORTS

import core.stdc.stdlib : exit;
import core.thread;
import std.array : replicate;
import std.conv : to;
import std.datetime : SysTime;
import std.file : dirEntries, exists, mkdirRecurse, readText, timeLastModified, write, SpanMode;
import std.stdio : writeln;
import std.string : endsWith, indexOf, join, lastIndexOf, replace, split, startsWith, strip, stripRight, toUpper;

// -- TYPES

class LINE
{
    // -- ATTRIBUTES

    long
        LineIndex,
        SpaceCount;
    string
        Text;
    long
        DeclarationSpaceCount;
    string
        DeclarationText;
    long
        ImplementationSpaceCount;
    string
        ImplementationText;
    bool
        IsProcessed;

    // -- CONSTRUCTORS

    this(
        )
    {
    }

    // -- INQUIRIES

    bool IsImplementationTag(
        )
    {
        return Text == "::";
    }

    // ~~

    bool IsDecorator(
        )
    {
        return
            Text == "@"
            || Text.startsWith( "@ " );
    }

    // ~~

    bool IsStruct(
        )
    {
        return Text.startsWith( "struct " );
    }

    // ~~

    bool IsClass(
        )
    {
        return Text.startsWith( "class " );
    }

    // ~~

    bool IsType(
        )
    {
        return
            IsStruct()
            || IsClass();
    }

    // ~~

    bool IsMethod(
        )
    {
        return Text.endsWith( "(" );
    }

    // ~~

    bool IsImplementationMethod(
        )
    {
        return
            IsMethod()
            && ( Text.startsWith( "::" )
                 || Text.indexOf( " ::" ) >= 0 );
    }

    // ~~

    bool IsOpeningBrace(
        )
    {
        return Text == "{";
    }

    // ~~

    bool IsClosingBrace(
        )
    {
        return
            Text == "}"
            || Text == "};";
    }

    // ~~

    string GetDecoratorText(
        )
    {
        if ( Text.startsWith( "@ " ) )
        {
            return Text[ 2 .. $ ];
        }
        else
        {
            return "";
        }
    }

    // ~~

    string GetDeclarationText(
        )
    {
        if ( DeclarationText == "" )
        {
            return "";
        }
        else
        {
            return GetSpaceText( DeclarationSpaceCount ) ~ DeclarationText;
        }
    }

    // ~~

    string GetImplementationText(
        )
    {
        if ( ImplementationText == "" )
        {
            return "";
        }
        else
        {
            return GetSpaceText( ImplementationSpaceCount ) ~ ImplementationText;
        }
    }

    // ~~

    void Print(
        )
    {
        writeln(
            "["
            ~ ( LineIndex + 1 ).to!string()
            ~ "] "
            ~ GetSpaceText( DeclarationSpaceCount )
            ~ Text
            );
    }

    // -- OPERATIONS

    void SetText(
        string text
        )
    {
        text = text.stripRight();

        while ( SpaceCount < text.length
                && text[ SpaceCount ] == ' ' )
        {
            ++SpaceCount;
        }

        Text = text[ SpaceCount .. $ ];

        DeclarationSpaceCount = SpaceCount;
        DeclarationText = Text ~ "\n";

        ImplementationSpaceCount = 0;
        ImplementationText = "";

        IsProcessed = false;
    }

    // ~~

    void RemoveDeclarationText(
        )
    {
        DeclarationSpaceCount = 0;
        DeclarationText = "";
    }

    // ~~

    void RemoveImplementationText(
        )
    {
        ImplementationSpaceCount = 0;
        ImplementationText = "";
    }
}

// ~~

class CODE
{
    // -- ATTRIBUTES

    LINE[]
        LineArray;

    // -- INQUIRIES

    bool IsIdentifierCharacter(
        char character
        )
    {
        return
            ( character >= 'a' && character <= 'z' )
            || ( character >= 'A' && character <= 'Z' )
            || ( character >= '0' && character <= '9' )
            || character == '_';
    }

    // ~~

    string GetCleanText(
        string text
        )
    {
        string
            old_text;

        text = text.stripRight();

        if ( text != ""
             && !text.endsWith( '\n' ) )
        {
            text ~= '\n';
        }

        do
        {
            old_text = text;
            text = text.replace( "\n\n\n", "\n\n" );
        }
        while ( text != old_text );

        return text;
    }

    // ~~

    string GetDeclarationText(
        )
    {
        string
            declaration_text;

        foreach ( line; LineArray )
        {
            declaration_text ~= line.GetDeclarationText();
        }

        return GetCleanText( declaration_text );
    }

    // ~~

    string GetImplementationText(
        )
    {
        string
            implementation_text;

        foreach ( line; LineArray )
        {
            implementation_text ~= line.GetImplementationText();
        }

        return GetCleanText( implementation_text );
    }

    // ~~

    void PrintLines(
        long first_line_index,
        long post_line_index
        )
    {
        long
            line_index;

        for ( line_index = first_line_index;
              line_index < post_line_index;
              ++line_index )
        {
            LineArray[ line_index ].Print();
        }
    }

    // ~~

    void PrintError(
        string message,
        long line_index,
        long line_count = 1
        )
    {
        .PrintError( message );
        PrintLines( line_index, line_index + line_count );
    }

    // ~~

    long FindOpeningBraceIndex(
        long method_line_index,
        long method_line_space_count
        )
    {
        long
            line_index;
        LINE
            line;

        for ( line_index = method_line_index + 1;
              line_index >= 0 && line_index < LineArray.length;
              ++line_index )
        {
            line = LineArray[ line_index ];

            if ( line.IsOpeningBrace()
                 && line.SpaceCount == method_line_space_count )
            {
                return line_index;
            }

            if ( line.SpaceCount < method_line_space_count
                 && line.Text != "" )
            {
                return -1;
            }
        }

        return -1;
    }

    // ~~

    long FindClosingBraceIndex(
        long opening_brace_line_index,
        long method_line_space_count
        )
    {
        long
            line_index;
        LINE
            line;

        for ( line_index = opening_brace_line_index + 1;
              line_index >= 0 && line_index < LineArray.length;
              ++line_index )
        {
            line = LineArray[ line_index ];

            if ( line.IsClosingBrace()
                 && line.SpaceCount == method_line_space_count )
            {
                return line_index;
            }

            if ( line.SpaceCount < method_line_space_count
                 && line.Text != "" )
            {
                return -1;
            }
        }

        return -1;
    }

    // ~~

    string FindTypeName(
        long method_line_index,
        long method_line_space_count
        )
    {
        long
            line_index;
        string[]
            identifier_array;
        LINE
            line;

        for ( line_index = method_line_index - 1;
              line_index >= 0 && line_index < LineArray.length;
              --line_index )
        {
            line = LineArray[ line_index ];

            if ( line.IsType()
                 && line.SpaceCount == method_line_space_count - 4 )
            {
                identifier_array
                    = line.Text
                          .RemovePrefix( "struct " )
                          .RemovePrefix( "class " )
                          .strip()
                          .replace( "(", " " )
                          .replace( "<", " " )
                          .replace( ":", " " )
                          .split( " " );

                foreach ( identifier; identifier_array )
                {
                    if ( !identifier.endsWith( "_API" ) )
                    {
                        return identifier;
                    }
                }

                return "";
            }
        }

        return "";
    }

    // -- OPERATIONS

    void SetText(
        string text
        )
    {
        string[]
            text_line_array;
        LINE
            line;

        text = text.stripRight().replace( "\r", "" ).replace( "\t", "    " );
        text_line_array = text.split( "\n" );

        LineArray = null;

        foreach ( text_line; text_line_array )
        {
            line = new LINE();
            line.SetText( text_line );
            LineArray ~= line;
        }
    }

    // ~~

    void ProcessTags(
        )
    {
        long
            first_line_index,
            last_line_index,
            line_index;
        LINE
            first_line,
            last_line,
            line;

        for ( first_line_index = 0;
              first_line_index < LineArray.length;
              ++first_line_index )
        {
            first_line = LineArray[ first_line_index ];

            if ( first_line.IsImplementationTag() )
            {
                for ( last_line_index = first_line_index + 1;
                      last_line_index < LineArray.length;
                      ++last_line_index )
                {
                    last_line = LineArray[ last_line_index ];

                    if ( last_line.IsImplementationTag() )
                    {
                        first_line.RemoveDeclarationText();
                        first_line.RemoveImplementationText();
                        first_line.IsProcessed = true;

                        last_line.RemoveDeclarationText();
                        last_line.ImplementationSpaceCount = 0;
                        last_line.ImplementationText = "\n";
                        last_line.IsProcessed = true;

                        for ( line_index = first_line_index + 1;
                              line_index < last_line_index;
                              ++line_index )
                        {
                            line = LineArray[ line_index ];
                            line.RemoveDeclarationText();
                            line.ImplementationSpaceCount = line.SpaceCount - 4;
                            line.ImplementationText = line.Text ~ "\n";
                            line.IsProcessed = true;
                        }

                        first_line_index = last_line_index;
                    }
                }
            }
        }
    }

    // ~~

    void AddBodyLine(
        long decorator_line_index
        )
    {
        long
            line_index,
            opening_brace_line_index;
        LINE
            body_line,
            decorator_line,
            opening_brace_line;

        decorator_line = LineArray[ decorator_line_index ];

        for ( opening_brace_line_index = decorator_line_index;
              opening_brace_line_index < LineArray.length;
              ++opening_brace_line_index )
        {
            opening_brace_line = LineArray[ opening_brace_line_index ];

            if ( opening_brace_line.Text.endsWith( ";" ) )
            {
                return;
            }

            if ( opening_brace_line.SpaceCount < decorator_line.SpaceCount
                 && opening_brace_line.Text != "" )
            {
                return;
            }

            if ( opening_brace_line.IsOpeningBrace()
                 && opening_brace_line.SpaceCount == decorator_line.SpaceCount )
            {
                body_line = new LINE();
                body_line.SpaceCount = opening_brace_line.SpaceCount + 4;
                body_line.Text = "GENERATED_BODY()";
                body_line.DeclarationSpaceCount = body_line.SpaceCount;
                body_line.DeclarationText = body_line.Text ~ "\n\n";
                body_line.ImplementationSpaceCount = 0;
                body_line.ImplementationText = "";
                body_line.IsProcessed = true;

                LineArray
                    = LineArray[ 0 .. opening_brace_line_index + 1 ]
                      ~ body_line
                      ~ LineArray[ opening_brace_line_index + 1 .. $ ];

                return;
            }
        }
    }

    // ~~

    void ProcessDecorators(
        )
    {
        long
            line_index;
        LINE
            line,
            next_line;

        for ( line_index = 0;
              line_index + 1 < LineArray.length;
              ++line_index )
        {
            line = LineArray[ line_index ];

            if ( !line.IsProcessed )
            {
                if ( line.IsDecorator() )
                {
                    next_line = LineArray[ line_index + 1 ];

                    if ( next_line.IsStruct() )
                    {
                        line.DeclarationText = "USTRUCT(" ~ line.GetDecoratorText() ~ ")\n";

                        AddBodyLine( line_index );
                    }
                    else if ( next_line.IsClass() )
                    {
                        line.DeclarationText = "UCLASS(" ~ line.GetDecoratorText() ~ ")\n";

                        AddBodyLine( line_index );
                    }
                    else if ( next_line.IsMethod() )
                    {
                        line.DeclarationText = "UFUNCTION(" ~ line.GetDecoratorText() ~ ")\n";
                    }
                    else
                    {
                        line.DeclarationText = "UPROPERTY(" ~ line.GetDecoratorText() ~ ")\n";
                    }

                    line.IsProcessed = true;
                }
            }
        }
    }

    // ~~

    void ProcessMethods(
        )
    {
        long
            assignment_character_index,
            closing_brace_line_index,
            declaration_line_index,
            implementation_line_index,
            method_line_index,
            opening_brace_line_index;
        string
            type_name;
        LINE
            declaration_line,
            implementation_line,
            method_line;

        for ( method_line_index = 0;
              method_line_index + 1 < LineArray.length;
              ++method_line_index )
        {
            method_line = LineArray[ method_line_index ];

            if ( !method_line.IsProcessed
                 && method_line.IsImplementationMethod() )
            {
                type_name = FindTypeName( method_line_index, method_line.SpaceCount );
                opening_brace_line_index = FindOpeningBraceIndex( method_line_index, method_line.SpaceCount );
                closing_brace_line_index = FindClosingBraceIndex( opening_brace_line_index, method_line.SpaceCount );

                if ( type_name != ""
                     && opening_brace_line_index >= 0
                     && closing_brace_line_index >= 0 )
                {
                    method_line.Text = method_line.Text;

                    method_line.DeclarationSpaceCount = method_line.SpaceCount;
                    method_line.DeclarationText
                        = method_line.Text .RemoveTypeName()
                          ~ "\n";

                    method_line.ImplementationSpaceCount = method_line.SpaceCount - 4;
                    method_line.ImplementationText
                        = method_line.Text
                              .RemovePrefix( "explicit " )
                              .RemovePrefix( "virtual " )
                              .AddTypeName( type_name )
                          ~ "\n";

                    for ( declaration_line_index = method_line_index + 1;
                          declaration_line_index < opening_brace_line_index;
                          ++declaration_line_index )
                    {
                        declaration_line = LineArray[ declaration_line_index ];
                        declaration_line.ImplementationSpaceCount = declaration_line.SpaceCount - 4;

                        assignment_character_index = declaration_line.Text.indexOf( " = " );

                        if ( assignment_character_index > 0 )
                        {
                            declaration_line.ImplementationText = declaration_line.Text.split( " = " )[ 0 ];

                            if ( declaration_line.Text.endsWith( "," ) )
                            {
                                declaration_line.ImplementationText ~= ",\n";
                            }
                            else
                            {
                                 declaration_line.ImplementationText ~= "\n";
                            }
                        }
                        else
                        {
                            declaration_line.ImplementationText = declaration_line.Text ~ "\n";
                        }

                        if ( declaration_line_index == opening_brace_line_index - 1 )
                        {
                            declaration_line.DeclarationText
                                = declaration_line.Text
                                      .ReplaceSuffix( ")", ");" )
                                      .ReplaceSuffix( ") override", ") override;" )
                                  ~ "\n";

                            declaration_line.ImplementationText
                                = declaration_line.Text
                                      .ReplaceSuffix( ") override", ")" )
                                  ~ "\n";
                        }
                    }

                    for ( implementation_line_index = opening_brace_line_index;
                          implementation_line_index <= closing_brace_line_index;
                          ++implementation_line_index )
                    {
                        implementation_line = LineArray[ implementation_line_index ];
                        implementation_line.RemoveDeclarationText();
                        implementation_line.ImplementationSpaceCount = implementation_line.SpaceCount - 4;
                        implementation_line.ImplementationText = implementation_line.Text ~ "\n";

                        if ( implementation_line_index == closing_brace_line_index )
                        {
                            implementation_line.ImplementationText ~= "\n";
                        }
                    }
                }
            }
        }
    }

    // ~~

    void Process(
        )
    {
        ProcessTags();
        ProcessDecorators();
        ProcessMethods();
    }
}

class FILE
{
    string
        ScriptFilePath,
        DeclarationFilePath,
        ImplementationFilePath;
    bool
        ScriptFileExists;
    SysTime
        ScriptFileTime,
        DeclarationFileTime,
        ImplementationFileTime;

    // ~~

    this(
        string script_file_path,
        string declaration_file_path,
        string implementation_file_path
        )
    {
        ScriptFilePath = script_file_path;
        DeclarationFilePath = declaration_file_path;
        ImplementationFilePath = implementation_file_path;
    }

    // ~~

    void Process(
        bool modification_time_is_used
        )
    {
        bool
            declaration_file_exists,
            implementation_file_exists;
        string
            declaration_file_text,
            implementation_file_text,
            script_file_text;
        SysTime
            declaration_file_time,
            implementation_file_time,
            script_file_time;
        CODE
            code;

        if ( ScriptFileExists )
        {
            script_file_time = ScriptFilePath.timeLastModified();

            declaration_file_exists = DeclarationFilePath.exists();

            if ( declaration_file_exists )
            {
                declaration_file_time = DeclarationFilePath.timeLastModified();
            }

            implementation_file_exists = ImplementationFilePath.exists();

            if ( implementation_file_exists )
            {
                implementation_file_time = ImplementationFilePath.timeLastModified();
            }

            if ( !modification_time_is_used
                 || !declaration_file_exists
                 || !implementation_file_exists
                 || script_file_time != ScriptFileTime
                 || declaration_file_time != DeclarationFileTime
                 || implementation_file_time != ImplementationFileTime )
            {
                script_file_text = ScriptFilePath.ReadText();

                code = new CODE();
                code.SetText( script_file_text );
                code.Process();

                DeclarationFilePath.WriteText( code.GetDeclarationText() );
                ImplementationFilePath.WriteText( code.GetImplementationText() );

                ScriptFileTime = ScriptFilePath.timeLastModified();
                DeclarationFileTime = DeclarationFilePath.timeLastModified();
                ImplementationFileTime = ImplementationFilePath.timeLastModified();
            }
        }
    }
}

// -- VARIABLES

bool
    CreateOptionIsEnabled,
    WatchOptionIsEnabled;
long
    PauseDuration;
string
    DeclarationFileExtention,
    DeclarationFolderPath,
    ImplementationFileExtension,
    ImplementationFolderPath,
    ScriptFileExtension,
    ScriptFolderPath;
FILE[ string ]
    FileMap;

// -- FUNCTIONS

void PrintError(
    string message
    )
{
    writeln( "*** ERROR : ", message );
}

// ~~

void Abort(
    string message
    )
{
    PrintError( message );

    exit( -1 );
}

// ~~

void Abort(
    string message,
    Exception exception
    )
{
    PrintError( message );
    PrintError( exception.msg );

    exit( -1 );
}

// ~~

string GetSpaceText(
    long space_count
    )
{
    if ( space_count <= 0 )
    {
        return "";
    }
    else
    {
        return " ".replicate( space_count );
    }
}

// ~~

string RemovePrefix(
    string text,
    string prefix
    )
{
    if ( text.startsWith( prefix ) )
    {
        return text[ prefix.length .. $ ];
    }
    else
    {
        return text;
    }
}

// ~~

string ReplaceSuffix(
    string text,
    string old_suffix,
    string new_suffix
    )
{
    if ( text.endsWith( old_suffix ) )
    {
        return text[ 0 .. ( text.length - old_suffix.length ) ] ~ new_suffix;
    }
    else
    {
        return text;
    }
}

// ~~

string RemoveTypeName(
    string text
    )
{
    if ( text.startsWith( "::" ) )
    {
        return text[ 2 .. $ ];
    }
    else
    {
        return text.replace( " ::", " " );
    }
}

// ~~

string AddTypeName(
    string text,
    string type_name
    )
{
    if ( text.startsWith( "::" ) )
    {
        return type_name ~ text;
    }
    else
    {
        return text.replace( " ::", " " ~ type_name ~ "::" );
    }
}

// ~~

string GetLogicalPath(
    string path
    )
{
    return path.replace( '\\', '/' );
}

// ~~

string GetFolderPath(
    string file_path
    )
{
    long
        slash_character_index;

    slash_character_index = file_path.lastIndexOf( '/' );

    if ( slash_character_index >= 0 )
    {
        return file_path[ 0 .. slash_character_index + 1 ];
    }
    else
    {
        return "";
    }
}

// ~~

void CreateFolder(
    string folder_path
    )
{
    if ( folder_path != ""
         && folder_path != "/"
         && !folder_path.exists() )
    {
        writeln( "Creating folder : ", folder_path );

        try
        {
            folder_path.mkdirRecurse();
        }
        catch ( Exception exception )
        {
            Abort( "Can't create folder : " ~ folder_path, exception );
        }
    }
}

// ~~

void WriteText(
    string file_path,
    string file_text,
    bool content_is_ignored = false
    )
{
    if ( CreateOptionIsEnabled )
    {
        CreateFolder( file_path.GetFolderPath() );
    }

    try
    {
        if ( content_is_ignored
             || !file_path.exists()
             || file_path.readText() != file_text )
        {
            writeln( "Writing file : ", file_path );

            file_path.write( file_text );
        }
    }
    catch ( Exception exception )
    {
        Abort( "Can't write file : " ~ file_path, exception );
    }
}

// ~~

string ReadText(
    string file_path
    )
{
    string
        file_text;

    writeln( "Reading file : ", file_path );

    try
    {
        file_text = file_path.readText();
    }
    catch ( Exception exception )
    {
        Abort( "Can't read file : " ~ file_path, exception );
    }

    return file_text;
}

// ~~

void FindFiles(
    )
{
    string
        script_file_path,
        declaration_file_path,
        implementation_file_path;
    FILE *
        file;

    foreach ( old_file; FileMap )
    {
        old_file.ScriptFileExists = false;
    }

    foreach ( script_folder_entry; dirEntries( ScriptFolderPath, "*" ~ ScriptFileExtension, SpanMode.depth ) )
    {
        if ( script_folder_entry.isFile )
        {
            script_file_path = script_folder_entry.name.GetLogicalPath();

            if ( script_file_path.startsWith( ScriptFolderPath )
                 && script_file_path.endsWith( ScriptFileExtension ) )
            {
                file = script_file_path in FileMap;

                if ( file is null )
                {
                    declaration_file_path
                        = DeclarationFolderPath
                          ~ script_file_path[ ScriptFolderPath.length .. $ - 4 ]
                          ~ DeclarationFileExtention;

                    implementation_file_path
                        = ImplementationFolderPath
                          ~ script_file_path[ ScriptFolderPath.length .. $ - 4 ]
                          ~ ImplementationFileExtension;

                    FileMap[ script_file_path ] = new FILE( script_file_path, declaration_file_path, implementation_file_path );

                    file = script_file_path in FileMap;
                }

                file.ScriptFileExists = file.ScriptFilePath.exists();
            }
        }
    }
}

// ~~

void ProcessFiles(
    bool modification_time_is_used
    )
{
    FindFiles();

    foreach ( ref file; FileMap )
    {
        file.Process( modification_time_is_used );
    }
}

// ~~

void WatchFiles(
    )
{
    ProcessFiles( false );

    if ( WatchOptionIsEnabled )
    {
        writeln( "Watching files..." );

        while ( true )
        {
            ProcessFiles( true );

            Thread.sleep( dur!( "msecs" )( PauseDuration ) );
        }
    }
}

// ~~

void main(
    string[] argument_array
    )
{
    string
        script_folder_path,
        option,
        declaration_folder_path;

    argument_array = argument_array[ 1 .. $ ];

    ScriptFileExtension = ".upp";
    DeclarationFileExtention = ".h";
    ImplementationFileExtension = ".cpp";
    CreateOptionIsEnabled = false;
    WatchOptionIsEnabled = false;
    PauseDuration = 500;

    while ( argument_array.length >= 1
            && argument_array[ 0 ].startsWith( "--" ) )
    {
        option = argument_array[ 0 ];

        argument_array = argument_array[ 1 .. $ ];

        if ( option == "--extension"
             && argument_array.length >= 3
             && argument_array[ 0 ].startsWith( '.' )
             && argument_array[ 1 ].startsWith( '.' )
             && argument_array[ 2 ].startsWith( '.' ) )
        {
            ScriptFileExtension = argument_array[ 0 ];
            DeclarationFileExtention = argument_array[ 1 ];
            ImplementationFileExtension = argument_array[ 2 ];

            argument_array = argument_array[ 3 .. $ ];
        }
        else if ( option == "--create" )
        {
            CreateOptionIsEnabled = true;
        }
        else if ( option == "--watch" )
        {
            WatchOptionIsEnabled = true;
        }
        else if ( option == "--pause"
                  && argument_array.length >= 1 )
        {
            PauseDuration = argument_array[ 0 ].to!long();

            argument_array = argument_array[ 1 .. $ ];
        }
        else
        {
            PrintError( "Invalid option : " ~ option );
        }
    }

    if ( argument_array.length == 0 )
    {
        ScriptFolderPath = "";
        DeclarationFolderPath = "";
        ImplementationFolderPath = "";
        WatchFiles();
    }
    else if ( argument_array.length == 1
              && argument_array[ 0 ].GetLogicalPath().endsWith( '/' ) )
    {
        ScriptFolderPath = argument_array[ 0 ].GetLogicalPath();
        DeclarationFolderPath = ScriptFolderPath;
        ImplementationFolderPath = ScriptFolderPath;
        WatchFiles();
    }
    else if ( argument_array.length == 2
              && argument_array[ 0 ].GetLogicalPath().endsWith( '/' )
              && argument_array[ 1 ].GetLogicalPath().endsWith( '/' ) )
    {
        ScriptFolderPath = argument_array[ 0 ].GetLogicalPath();
        DeclarationFolderPath = argument_array[ 1 ].GetLogicalPath();
        ImplementationFolderPath = DeclarationFolderPath;
        WatchFiles();
    }
    else if ( argument_array.length == 3
              && argument_array[ 0 ].GetLogicalPath().endsWith( '/' )
              && argument_array[ 1 ].GetLogicalPath().endsWith( '/' )
              && argument_array[ 2 ].GetLogicalPath().endsWith( '/' ) )
    {
        ScriptFolderPath = argument_array[ 0 ].GetLogicalPath();
        DeclarationFolderPath = argument_array[ 1 ].GetLogicalPath();
        ImplementationFolderPath = argument_array[ 2 ].GetLogicalPath();
        WatchFiles();
    }
    else
    {
        writeln( "Usage :" );
        writeln( "    surreal [options]" );
        writeln( "    surreal [options] <FOLDER>" );
        writeln( "    surreal [options] <INPUT_FOLDER> <OUTPUT_FOLDER>" );
        writeln( "    surreal [options] <SCRIPT_FOLDER> <DECLARATION_FOLDER> <IMPLEMENTATION_FOLDER>" );
        writeln( "Options :" );
        writeln( "    --extension <script-extension> <declaration-extension> <implementation-extension>" );
        writeln( "    --create" );
        writeln( "    --watch" );
        writeln( "    --pause 500" );
        writeln( "Examples :" );
        writeln( "    surreal" );
        writeln( "    surreal --watch" );
        writeln( "    surreal --create UPP/ H/ CPP/" );
        writeln( "    surreal --extension .upp .h .cpp --create --watch UPP/ H/ CPP/" );

        PrintError( "Invalid arguments : " ~ argument_array.to!string() );
    }
}
