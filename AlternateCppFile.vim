" Exposed globally for ease of testing
let g:invalid_cpp_file_enum  = 0
let g:source_cpp_file_enum   = 1
let g:header_cpp_file_enum   = 2
let g:template_cpp_file_enum = 3

" Translates a valid cpp file name to
" a cpp file enum defined at the top of the file
function! IdentifyCppFileType(cpp_file)
    if a:cpp_file =~ '\S\+\.H$' && a:cpp_file !~ '\.Impl\.H$'
        return g:header_cpp_file_enum
    elseif a:cpp_file =~ '\S\+\.C$'
        return g:source_cpp_file_enum
    elseif a:cpp_file =~ '\S\+\.Impl\.H$'
        return g:template_cpp_file_enum
    else
        return g:invalid_cpp_file_enum
    endif
endfunction

" Returns a list of appropriate alternate cpp
" file extensions of a cpp file enum
function! GetCppFilesAlternates(cpp_file_enum)
    if a:cpp_file_enum == g:header_cpp_file_enum
        return [".C", ".Impl.H"]
    elseif a:cpp_file_enum == g:source_cpp_file_enum || a:cpp_file_enum == g:template_cpp_file_enum
        return [".H"]
    else
        return []
    endif
endfunction

" Returns the given path+filename minus extensions of a cpp file
" Assumes the caller passes the correct cpp file enum
function! GetCppFileWithoutExtension(cpp_file_enum, cpp_file)
    if a:cpp_file_enum == g:header_cpp_file_enum || a:cpp_file_enum == g:source_cpp_file_enum
        return fnamemodify(a:cpp_file, ":r")
    elseif a:cpp_file_enum == g:template_cpp_file_enum
        let l:without_first_extension = fnamemodify(a:cpp_file, ":r")
        return fnamemodify(l:without_first_extension, ":r")
    else
        return ""
    endif
endfunction

" Wrapped vim's facilities to check if a file exists into
" a function, solely for mocking in unit tests, I am not
" aware of a better way to do this in vimscript at this time
function! DoesFileExistAlready(file_name)
    return !empty(glob(a:file_name))
endfunction

" Gets a cpp file's alternate file, only if it exists already
" for .H which has multiple possible alternates, .C takes priority over .Impl.H
function! AlternatePreexistingCppFile(file_name)
    let l:file_type_enum = IdentifyCppFileType(a:file_name)

    if l:file_type_enum != g:invalid_cpp_file_enum
        let l:base_file_name          = GetCppFileWithoutExtension(l:file_type_enum, a:file_name)
        let l:alt_cpp_file_extensions = GetCppFilesAlternates(l:file_type_enum)

        for extension in l:alt_cpp_file_extensions
            let l:alt_file = l:base_file_name . extension
            if DoesFileExistAlready(l:alt_file)
                return l:alt_file
            endif
        endfor
    endif

    return ""
endfunction

function! EditAlternateExistingCppFile()
    let l:alt_cpp_file = AlternatePreexistingCppFile(bufname("%"))
    if !empty(l:alt_cpp_file)
        execute ':e' l:alt_cpp_file
    endif
endfunction
