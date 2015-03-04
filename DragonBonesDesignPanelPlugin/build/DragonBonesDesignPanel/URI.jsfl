// ------------------------------------------------------------------------------------------------------------------------
//
//  ██  ██ ██████ ██
//  ██  ██ ██  ██ ██
//  ██  ██ ██  ██ ██
//  ██  ██ ██████ ██
//  ██  ██ ██ ██  ██
//  ██  ██ ██  ██ ██
//  ██████ ██  ██ ██
//
// ------------------------------------------------------------------------------------------------------------------------
// URI

	/**
	 * URI
	 * @overview	Handles URI and path conversion, including detection and resolution of relative paths
	 * @instance	URI
	 */

	xjsfl.init(this, ['Utils']);
		
	// ---------------------------------------------------------------------------------------------------------------
	// notes on JSFL and xJSFL URI juggling

		/*
			FLASH URI FORMAT

				Both
					URI format must be file:/// (the standard is file://<host>/<filepath>, but Flash ignores the host) @see http://en.wikipedia.org/wiki/File_URI_scheme

				Windows

					All relative URIs fail
					c:/ appears to be valid, as well as c|/
					Spaces appear to be valid, they get converted to %20 inside FLfile

				Mac

					Relative URIs, i.e. file.ext, ./file.ext and ../file.ext are relative to HD root
					Absolute URIs, i.e. /file.ext are relative to HD root
					Leading Hard drive name is valid, i.e. Macintosh HD/file, but NOT /Macintosh HD/file (note the leading slash)

			FLASH CONSTANTS

				Mac
					fl.configDirectory:	/Users/User Name/Library/Application Support/Adobe/Flash CS4/en/Configuration/
					fl.configURI:		file:///Macintosh%20HD/Users/User Name/Library/Application%20Support/Adobe/Flash%20CS4/en/Configuration/

				Windows
					fl.configDirectory:	F:\Users\User Name\AppData\Local\Adobe\Flash CS4\en\Configuration\
					fl.configURI:		file:///F|/Users/User%20Name/AppData/Local/Adobe/Flash%20CS4/en/Configuration/

			xJSFL STRING FORMAT

				Relative-location syntax

					Relative URIs, i.e. file, ./ or ../ are relative to the calling file
					/ on a mac points to the primary drive's root
					// on PC and Mac points to the xJSFL root
					C: or Drive: is relative to the drive (platform specific)

				Parsing

					Paths are parsed for

						- Relative-locations as outlined above (./, ../, /, //, c:, drive name:)
						- {placeholder} variables, which are replaced

					URIs and Paths are parsed for

						- drive names are converted to and from drive| and drive:
						- \ are converted to /
						- ../ are resolved
						- //+ are converted to /
						- Spaces are converted to %20


		*/

	// ---------------------------------------------------------------------------------------------------------------
	// # URI Instance - Instantiatable class that can be used to easily create and manipulate URI strings 

		/**
		 * URI Constructor
		 * @param	{String}	pathOrURI		A token, path or URI-formatted string
		 * @param	{Boolean}	pathOrURI		A Boolean, to get the current file
		 * @param	{String}	context			An optional uri or path context, from which to start the URI
		 * @param	{File}		context			An optional File from which to start the URI
		 * @param	{Folder}	context			An optional Folder from which to start the URI
		 * @param	{Number}	context			An optional stack-function index, the location of which to derive the URI from
		 */
		URI = function(pathOrURI, context)
		{
			// if pathOrURI is null, undefined, error
				if(typeof pathOrURI === 'undefined' || pathOrURI == null)
				{
					throw new Error('ReferenceError in URI.toURI(): pathOrURI cannot be undefined')
				}
			// if pathOrURI is true, grab the calling file
				if(pathOrURI === true)
				{
					pathOrURI = Utils.getStack()[1].uri;
				}
			// if pathOrURI is an empty string, grab the calling file's folder
				else if(pathOrURI === '')
				{
					pathOrURI = Utils.getStack()[1].path;
				}
				
			// update context
				if(typeof context === 'number')
				{
					context ++;
				}
	
			// assign URI
				this.uri = URI.toURI(pathOrURI, context || 1);
		}

		URI.prototype =
		{
			
			// --------------------------------------------------------------------------------
			// # Properties
			
				constructor:URI,
	
				/** @type {String}	The file:/// URI of the URI instance (casting the URI object to a String gives the same result) */
				uri:'',
	
				/** @type {String}	The folder path URI to the URI instance */
				get folder()
				{
					return URI.getFolder(this.uri);
				},
	
				/** @type {String}	The name of the file or folder referred to by the URI instance */
				get name()
				{
					return URI.getName(this.uri);
				},
	
				/** @type {String}	The name of the file or folder referred to by the URI instance */
				get extension()
				{
					return URI.getExtension(this.uri);
				},
	
				/** @type {String}	The platform-specific path of the file or folder referred to by the URI instance */
				get path()
				{
					return URI.asPath(this.uri);
				},
	
				/** @type {String}	The type of the URI, 'file' or 'folder' */
				get type()
				{
					return URI.isFile(this.uri) ? 'file' : 'folder';
				},
	
			// --------------------------------------------------------------------------------
			// # Methods
			
				/** @type {URI}		The parent folder of the file or folder referred to by the URI instance */
				getParent:function()
				{
					return new URI(URI.getParent(this.uri));
				},
	
				/**
				 * Returns a new URI that resolves to the target path or URI
				 * @param	{String}	pathOrURI	The target URI, such as '../../'
				 * @returns	{URI}					The new URI
				 */
				pathTo:function(pathOrURI)
				{
					return URI.pathTo(this.uri, pathOrURI);
				},
	
				/**
				 * The URI string of the URI instance
				 * @returns	{String}				The string of the URI, i.e. file://path/to/file.txt
				 */
				toString:function()
				{
					return this.uri;
				}
		}

	// ---------------------------------------------------------------------------------------------------------------
	// # Static methods - a host of static utility functions that can be used to manipulate paths or URIs 

		// ---------------------------------------------------------------------------------------------------------------
		// # Creation functions 

			/**
			 * Create an absolute URI from virtually any URI or path
			 *
			 * - Resolves relative paths (automatically or via context)
			 * - Allows concatenation and resolution of paths
			 * - Resolves source path relative to a target path
			 * - Expands registered {placeholder} variables
			 * - Tidies badly-formatted URIs
			 *
			 * @param	{String}	pathOrURI		A token, path or URI-formatted string
			 * @param	{Boolean}	pathOrURI		A Boolean, to get the current file
			 * @param	{String}	context			An optional uri or path context, from which to start the URI
			 * @param	{File}		context			An optional File from which to start the URI
			 * @param	{Folder}	context			An optional Folder from which to start the URI
			 * @param	{Number}	context			An optional stack-function index, the location of which to derive the URI from
			 * @param	{Boolean}	checkLength		An optional Boolean, to test resulting URIs are not longer than the 260 characters allowed for most FLfile operations. Defaults to true
			 * @returns	{String}					An absolute URI
			 */
			URI.toURI = function(pathOrURI, context, checkLength)
			{
				// ---------------------------------------------------------------------------------------------------------------
				// special cases for null, undefined, true or ''

					if( typeof context === 'number' || typeof context === 'undefined')
					{
						// if pathOrURI is null, undefined, error
							if(typeof pathOrURI === 'undefined' || pathOrURI == null)
							{
								throw new Error('ReferenceError in URI.toURI(): pathOrURI cannot be undefined')
							}
							
						// get stack index
							var stackIndex = typeof context === 'number' ? context + 1 : 1
							
						// if pathOrURI is true, grab the calling file
							if(pathOrURI === true)
							{
								pathOrURI = Utils.getStack()[stackIndex].uri;
							}
						// if pathOrURI is an empty string, grab the calling file's folder
							else if(pathOrURI === '')
							{
								pathOrURI = Utils.getStack()[stackIndex].path;
							}
					}

				// ---------------------------------------------------------------------------------------------------------------
				// parameters

					// parameters
						pathOrURI		= String(pathOrURI || '');
						context			= context || 0;
						checkLength 	= typeof checkLength === 'undefined' ? true : checkLength;
						
					// variables
						var uri;
						var root;
						var path;

					// debug
						//trace('1 > original  : ' + pathOrURI)

				// ---------------------------------------------------------------------------------------------------------------
				// exit early if path is a URI, i.e. file:/// (as we treat these as absolute, no matter what)

					// test for URI
						if(pathOrURI.indexOf('file:///') === 0)
						{
							// check length
								if(checkLength)
								{
									URI.checkURILength(pathOrURI);
								}

							// debug
								//trace('2 > URI       : ' + pathOrURI);
									
							// return immediately
								return URI.tidy(pathOrURI);
						}
					// set path to the pathOrURI
						else
						{
							path = pathOrURI.replace(/\\+/g, '/');
						}

					// debug
						//trace('3 > path      : ' + path);
							
				// ---------------------------------------------------------------------------------------------------------------
				// handle absolute paths / notation, i.e. //, /, {placeholder}, Macintosh HD:, c:

					// variables
						var rx			= /^(\/\/|\/|{|[\w ]+:)/;
						var matches		= path.match(rx);

					// parse relative-path formats to resolve root
						if(matches)
						{
							// take action on match results
								switch(matches[1])
								{
									// xJSFL folder
										case '//':
											root		= xjsfl.uri;
											path		= path.substr(2);
										break;
	
									// mac root folder
										case '/':
											// if Mac, set the root to '' as / signifies an absolute path to a root folder, or another drive root
												if(xjsfl.settings.app.os.mac)
												{
													root = '';
													path = path.substr(1);
												}
											
											// if PC, grab the root of the config URI
												else
												{
													root = fl.configURI.substr(0, 10);
												}
										break;
	
									// placeholder folder
										case '{':
											var matches = path.match(/{(\w+)}/);
											if(matches)
											{
												var folder = xjsfl.settings.folders[matches[1]];
												if(folder)
												{
													uri = path.replace(matches[0], folder);
												}
											}
											else
											{
												throw new URIError('Error in URI.toURI(): Unrecognised placeholder ' +matches[0]+ ' in path "' +path+ '"');
											}
										break;
	
									// drive, i.e., 'Macintosh HD:', 'C:'
										default:
											if(xjsfl.settings.app.os.mac)
											{
												root = path.replace(':', '/');
											}
											else
											{
												root = path.replace(':', '|');
											}
											path = '';
								}
								
							// create uri if a root was found
								if(root != null)
								{
									uri = root.replace(/\/+$/, '/') + path;
								}
	
							// debug
								//trace('4 > absolute  : ' + uri);
								
						}

				// ---------------------------------------------------------------------------------------------------------------
				// resolve relative tokens, i.e. resolve ./, ../, path/to/file.txt
				
					// if a URI isn't yet resolved, the path is relative, so we need to derive its context
						if( ! uri )
						{
							// ---------------------------------------------------------------------------------------------------------------
							// define root from context, i.e. get the starting location of the path reference

								// context is a number
								
									/*
										Now we're looking for relative paths, we need to work out the calling file.
										This is done by getting the current stack (an Array) of function calls, and
										working backwards.
										
										If there's no numeric context, that means we need to simply grab the URI of the
										function that called this function, so we set a stackIndex of 1 (1 step back).
										
										If there is an existing numeric context, we need to add 1 to it, so that we
										compensate for this function now being the top of the stack.
									*/
									if(typeof context === 'number')
									{
										var stack		= Utils.getStack();
										var object		= stack[context + 1];
										if(object)
										{
											root		= URI.getFolder(object.uri);
										}
										else
										{
											throw new ReferenceError('ReferenceError in URI.toURI(): The supplied call stack index (context) ' + stackIndex + ' is out of bounds');
										}
									}
									
								// context is a File
									else if(context instanceof File)
									{
										root = context.uri;
									}
									
								// context is a Folder
									else if(context instanceof Folder)
									{
										root = context.uri + '/';
									}
									
								// convert context to a string, and try to convert it to a URI
									else
									{
										context = String(context);
										if(URI.isURI(context))
										{
											root = URI.getFolder(context);
										}
										else
										{
											root = URI.toURI(context);
										}
									}
	
							// ---------------------------------------------------------------------------------------------------------------
							// check if a root was defined, and if so, derive the full URI
							
								if(root)
								{
									// check that path isn't absolute (or else it can't be resolved)
										if(URI.isAbsolute(path))
										{
											throw new URIError('Error in URI.toURI(): It is not possible to resolve the absolute path "' +path+ '" relative to "' +context+ '"');
										}
										else
										{
											uri = URI.getFolder(root) + path;
										}
								}
								else
								{
									throw new URIError('Error in URI.toURI(): It is not possible to resolve the path "' +path+ '" as the context "' +context+ '" as is not a valid URI, File or Folder');
								}
								
							// debug
								//trace('5 > relative  : ' + uri);
						}

				// ---------------------------------------------------------------------------------------------------------------
				// tidy URI

					// remove file:///
						if(uri.indexOf('file:///') === 0)
						{
							uri = uri.substr(8);
						}

					// tidy drive letter
						uri	= uri.replace(/^([a-z ]+):/i, '$1|');
						
					// check for leading /
						if(uri[0] === '/' && uri[1] !== '/')
						{
							//uri = uri.substr(1);
						}

					// tidy path
						uri = URI.tidy(uri);
						
					// replace spaces with %20 
						uri = uri.replace(/ /g, '%20');
						
					// add 'file:///'
						uri = 'file:///' + uri;

					// check that URI is on or below the legal limit of 260 chars
						if(checkLength !== false)
						{
							URI.checkURILength(uri);
						}

				// ---------------------------------------------------------------------------------------------------------------
				// done!

					// debug
						//trace('6 > final     : ' + uri);

					// return
						return uri;
			}

			/**
			 * Create a valid path from virtually any URI or path
			 *
			 * Has the same functionality of URI.toURI()
			 * @see #URI.toURI()
			 *
			 * @param	{String}	pathOrURI	A token, path or URI-formatted string
			 * @param	{Boolean}	shorten		An optional Boolean to return a path with {placeholder} variables for registered URIs
			 * @returns	{String}				An absolute, or shortened path
			 */
			URI.toPath = function(pathOrURI, shorten)
			{
				// variables
					var path;
					var uri;
					
				// if absolute URI, we need some preprocessing
					if(URI.isURI(pathOrURI))
					{
						// remove file:/// so it will get processed by URI.asPath()
							uri = String(pathOrURI).substr(8);
							
						// tidy URI
							uri = URI.tidy(uri);
					}
					
				// parse all input via toURI()
					else
					{
						uri = URI.toURI(pathOrURI, 1);
					}
					
				// convert
					path = URI.asPath(uri, shorten);
					
				// add leading slash for mac absolute paths
					if(URI.isAbsolute(pathOrURI) && xjsfl.settings.app.os.mac)
					{
						path = '/' + path;
					}
				
				// return result
					return path;
			}


		// ---------------------------------------------------------------------------------------------------------------
		// # Conversion functions 

			/**
			 * Perform simple path to URI conversion
			 * @param	{String}	path		A valid path
			 * @param	{Boolean}	checkLength	An optional Boolean, to test resulting URIs are not longer than the 260 characters allowed for most FLfile operations. Defaults to true
			 * @returns	{String}				A URI-formatted string
			 */
			URI.asURI = function(pathOrURI, checkLength)
			{
				// variable
					var uri;
					pathOrURI = String(pathOrURI);

				// convert
					if(URI.isURI(pathOrURI))
					{
						uri = pathOrURI;
					}
					else
					{
						uri = pathOrURI
							// replace backslashes
								.replace(/\\+/g, '/')

							// replace double-slashes
								.replace(/\/+/g, '/')

							// replace redundant ./
								.replace(/(^|\/)\.\//img, '$1')

							// replace spaces with %20
								.replace(/ /g, '%20')

							// tidy drive letter or name
								.replace(/^([a-z ]+):/i, '$1|')

							// add 'file:///'
								uri = 'file:///' + uri;
					}

				// check that URI is on or below the legal limit of 260 chars
					if( (checkLength !== false) && uri.length > 260 )
					{
						URI.throwURILengthError(uri);
					}

				// return
					return uri;
			}

			/**
			 * Perform simple URI to path conversion
			 * @param	{String}	uri			A valid URI string
			 * @param	{URI}		uri			A valid URI instance
			 * @param	{Boolean}	shorten		An optional Boolean to return a path with {placeholder} variables for registered URIs
			 * @returns	{String}				A path-formatted string
			 */
			URI.asPath = function(pathOrURI, shorten)
			{
				// convert to string
					pathOrURI = String(pathOrURI);
				
				// return the {placeholder} version of registered URIs
					if(shorten && URI.isURI(pathOrURI))
					{
						// variables
							var folders = [];
							var uri		= pathOrURI;

						// get all folders matching the input URI
							for(var folder in xjsfl.settings.folders)
							{
								var folderURI = xjsfl.settings.folders[folder];
								if(uri.indexOf(folderURI) === 0)
								{
									folders.push({name:folder, uri:folderURI});
								}
							}

						// if there are any matches, sort the list and grab the longest match
							if(folders.length)
							{
								Utils.sortOn(folders, 'name');
								var folder = folders.shift();
								uri = uri.replace(folder.uri, '{' +folder.name+ '}');
							}

						// re-set uri variable
							pathOrURI = uri;
					}

				// convert to path format
					var path = pathOrURI
						// remove file:///
							.replace('file:///', '')

						// replace N| with N:
							.replace(/(^[a-z])\|/i, '$1:')

						// replace Drive Name: with Drive Name/
							.replace(/(^[a-z ]{2,}):\/?/i, '$1/')

						// replace \ with /
							.replace(/\\/g, '/')

						// replace %20 with spaces
							.replace(/%20/g, ' ');

				// return
					return path;
			}


		// ---------------------------------------------------------------------------------------------------------------
		// # Testing functions 

			/**
			 * Test if the supplied value is a URI-formatted string
			 * @param	{String}	pathOrURI	A valid path or URI
			 * @returns	{Boolean}				true or false, depending on the result
			 */
			URI.isURI = function(pathOrURI)
			{
				return (typeof pathOrURI === 'string' || pathOrURI instanceof URI) && String(pathOrURI).indexOf('file:///') === 0;
			}

			/**
			 * Test if the supplied value is a path-formatted string, such as c:/path/to/file.txt or /path
			 * @param	{String}	pathOrURI	A valid path or URI
			 * @returns	{Boolean}				true or false, depending on the result
			 */
			URI.isPath = function(pathOrURI)
			{
				return typeof pathOrURI === 'string' && pathOrURI.indexOf('file:///') === -1;
			}

			/**
			 * Tests if a path or URI is absolute (includes tokens and special xJSFL syntax)
			 * @param	{String}	pathOrURI	A valid path or URI
			 * @returns	{Boolean}				true or false, depending on the result
			 */
			URI.isAbsolute = function(pathOrURI)
			{
				return URI.isURI(pathOrURI) || /^([\w ]+[:\|]|\/|{\w+})/.test(String(pathOrURI));
			}

			/**
			 * Tests if a path or URI is relative (includes tokens and special xJSFL syntax)
			 * @param	{String}	pathOrURI	A valid path or URI
			 * @returns	{Boolean}				true or false, depending on the result
			 */
			URI.isRelative = function(pathOrURI)
			{
				return ! URI.isAbsolute(pathOrURI);
			}

			/**
			 * Tests if a path or URI looks like a filename, rather than a folder
			 * @param	{String}	pathOrURI	A valid path or URI
			 * @returns	{Boolean}				true or false, depending on the result
			 */
			URI.isFile = function(pathOrURI)
			{
				return ! /[\/\\]$/.test(String(pathOrURI));
			}

			/**
			 * Tests if a path or URI looks like a folder, rather than a filename
			 * @param	{String}	pathOrURI	A valid path or URI
			 * @returns	{Boolean}				true or false, depending on the result
			 */
			URI.isFolder = function(pathOrURI)
			{
				return pathOrURI == '' || /[\/\\]$/.test(String(pathOrURI));
			}

			/**
			 * Tests if a path or URI is at the highest folder level it can go
			 * @param	{String}	pathOrURI	A valid path or URI
			 * @returns	{Boolean}				true or false, depending on the result
			 */
			URI.isRoot = function(pathOrURI)
			{
				return pathOrURI != null ? /^([\w ]+[:|]\/?|\/)$/.test(String(pathOrURI).replace('file:///', '')) : false;
			}


		// ---------------------------------------------------------------------------------------------------------------
		// # Extraction functions 

			/**
			 * Returns the file or folder name of the item referenced by the path or URI (note names are unescaped)
			 * @param	{String}	pathOrURI		A vald path or URI
			 * @param	{Boolean}	removeExtension	An optional Boolean to remove the extension
			 * @returns	{String}					The file or folder name
			 */
			URI.getName = function(pathOrURI, removeExtension)
			{
				var name = (String(pathOrURI).replace(/\/$/, '')).split(/[\/\\]/).pop().replace(/%20/, ' ');
				return removeExtension ? name.replace(/\.\w+$/, '') : name;
			}

			/**
			 * Returns the file extension
			 * @param	{String}	pathOrURI		A vald path or URI
			 * @returns	{String}					The file extensions
			 */
			URI.getExtension = function(pathOrURI)
			{
				var match = String(pathOrURI).match(/\.(\w+)$/);
				return match ? match[1] : '';
			}
			
			/**
			 * Returns the current folder path of the item referenced by the path or URI
			 * @param	{String}	pathOrURI	A valid path or URI
			 * @returns	{String}				The folder of the path or URI
			 */
			URI.getFolder = function(pathOrURI)
			{
				return String(pathOrURI).replace(/([^\/\\]+)$/, '');
			}

			/**
			 * Returns the parent folder of the item referenced by the path or URI (for folders, this is the parent folder)
			 * @param	{String}	pathOrURI	A valid path or URI
			 * @returns	{String}				The folder of the path or URI
			 */
			URI.getParent = function(pathOrURI)
			{
				// ensure pathOrURI is a string
					pathOrURI	= String(pathOrURI);

				// remove file:/// and drive name or letter
					var matches	= pathOrURI.match(/(.+[:|]\/?)/);
					var drive	= matches ? matches[1] : '';
					var path	= pathOrURI.substr(drive.length);

				// remove final segment
					var rx		= /[^\/\\]+[\/\\]?$/;
					return drive + path.replace(rx, '');
			}

			/**
			 * Resolves the common (branch) path between 2 paths or URIs
			 * @param	{String}	src		A source path or URI
			 * @param	{String}	trg		A target path or URI
			 * @returns	{String}			The common ancestor path or URI
			 */
			URI.getBranch = function(src, trg)
			{
				// throw error if src and trg are not both the same format
					if(URI.isURI(src) && ! URI.isURI(trg))
					{
						throw new URIError('URIError in URI.common(): both src and trg parameters must be either paths or URIs');
					}
				
				// variables
					var branch		= '';
					var srcParts	= String(src).split('/');
					var trgParts	= String(trg).split('/');

				// loop over folders and grab common ancestors
					while(srcParts.length > 1 && srcParts[0] == trgParts[0])
					{
						srcParts.shift();
						branch += trgParts.shift() + '/';
					}
					
				// return
					return branch === 'file:///' ? '' : branch;
			}

			/**
			 * Resolves a path from the Source URI to a target URI, returning a relative path-formatted path
			 * @param	{String}	src			The source path or URI
			 * @param	{String}	trg			The target path or URI
			 * @returns	{String}				The new relative path between the two, or the absolute URI if there's no relationship
			 */
			URI.pathTo = function(src, trg)
			{
				// convert to Strings
					src = String(src);
					trg = String(trg);
				
				// throw error if src and trg are not both the same format
					if(URI.isURI(src) && ! URI.isURI(trg))
					{
						throw new URIError('URIError in URI.pathTo(): both src and trg parameters must be either paths or URIs');
					}

				// variables
					var trgPath;
					var branch = URI.getBranch(src, trg);

				// no relationship, so just return the trgURI
					if(branch === '')
					{
						trgPath = trg;
					}
					
				// otherwise, determine relationship between srcURI and trgURI
					else
					{
						// grab the remaining segments
							var srcParts	= src.substr(branch.length).split('/');
							var trgParts	= trg.substr(branch.length).split('/');
							
						// src is same level, so path will be 'trg.txt'
							if(srcParts.length == 1 && trgParts.length == 1)
							{
								trgPath = trgParts.pop();
							}
						// src is below, so path will be '../../trg.txt'
							else if(srcParts.length > 1)
							{
								trgPath = '../'.repeat(srcParts.length - 1) + trgParts.join('/');
							}
						// src is above, so path will be 'path/to/trg.txt'
							else if(srcParts.length < trgParts.length)
							{
								trgPath = trgParts.join('/');
							}
					}

				// return
					return URI.asPath(trgPath);
			}
			
			/**
			 * Returns the path or URI truncated to the supplied folder name or path
			 * @param	{String}	pathOrURI	A path or URI string
			 * @param	{URI}		pathOrURI	A URI instance
			 * @param	{String}	folder		The name or partial name of a folder to find in the path
			 * @returns	{String}				The new URI or path
			 */
			URI.findFolder = function(pathOrURI, folder)
			{
				// build the string to match the folder
					var str = '^.*' + Utils.rxEscape(folder);
					if( ! /\/$/.test(folder))
					{
						str += '.*?/'; // only add wildcard if the last character is not a slash
					}

				// match and return
					var rx			= new RegExp(str, 'i');
					var matches		= String(pathOrURI).match(rx);
					return matches ? matches[0] : null;
			}

			/**
			 * Re-targets a specified portion of a URI (or URIs) to point at a new folder
			 * @param	{String}	src			The source path or URI
			 * @param	{String}	trg			A folder you want to retarget to, from the source base and downwards
			 * @param	{String}	base		The name or partial name of a folder in the src path or URI you want to branch from
			 * @returns	{String}				The new path or URI
			 * @returns	{Array}					An Array of new paths or URIs
			 */
			URI.reTarget = function(src, trg, base)
			{
				// tidy variables so subsequent comparisons work
					src		= URI.tidy(src);
					trg		= URI.tidy(trg);
					base	= URI.tidy(base);
				
				// if base is relative, 
					if(base.indexOf('..') !== -1)
					{
						var folder = URI.getFolder(src);
						base = URI.tidy(folder + base);
					}
					
				// retarget
					base	= URI.findFolder(src, base);
					trg		= URI.getFolder(trg);
					
				// return
					return trg + src.substr(base.length);
			}

		// ---------------------------------------------------------------------------------------------------------------
		// # Utility functions 

			URI.tidy = function(pathOrURI)
			{
				// cast to string
					pathOrURI = String(pathOrURI);

				// remove file:/// & convert spaces to %20
					var protocol = '';
					if(pathOrURI.indexOf('file:///') > -1)
					{
						protocol =  'file:///';
						pathOrURI = pathOrURI.substr(8).replace(/ /g, '%20');
					}

				// replace backslashes
					pathOrURI = pathOrURI.replace(/\\+/g, '/');

				// replace double-slashes
					pathOrURI = pathOrURI.replace(/\/+/g, '/');

				// replace redundant ./
					pathOrURI = pathOrURI.replace(/(^|\/)\.\//img, '$1');

				// resolve relative tokens
					while(pathOrURI.indexOf('../') > 0)
					{
						// kill folder/../ pairs
							pathOrURI = pathOrURI.replace(/(^|\/)[^\/]+\/\.\.\//, '/');

						// replace any leading ../ tokens (as you can't go higher than root)
							pathOrURI = pathOrURI.replace(/^([a-z ]+[:|])\/[.\/]+/img, '$1/');
							//path = path.replace(/^\/\.\.\//img, '');
					}
					
				// return
					return protocol + pathOrURI;
			}

			/**
			 * Checks that the length of a URI is not longer than the maximum 260 characters supported by FLfile
			 * @param	{String}	uri			A URI
			 * @returns	{Boolean}				true of false depending on the result
			 */
			URI.checkURILength = function(uri)
			{
				if(uri.length > 260)
				{
					URI.throwURILengthError(uri);
				}
			}

			URI.throwURILengthError = function(uri)
			{
				throw new URIError('The URI for path "' +URI.asPath(uri)+ '" is more than 260 characters.');
			}

			URI.toString = function()
			{
				return '[class URI]';
			}


	// ---------------------------------------------------------------------------------------------------------------
	// register

		xjsfl.classes.register('URI', URI);
