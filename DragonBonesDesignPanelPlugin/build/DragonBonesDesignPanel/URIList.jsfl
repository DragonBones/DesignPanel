// ------------------------------------------------------------------------------------------------------------------------
//
//  ██  ██ ██████ ██ ██     ██        ██   
//  ██  ██ ██  ██ ██ ██               ██   
//  ██  ██ ██  ██ ██ ██     ██ █████ █████ 
//  ██  ██ ██████ ██ ██     ██ ██     ██   
//  ██  ██ ██ ██  ██ ██     ██ █████  ██   
//  ██  ██ ██  ██ ██ ██     ██    ██  ██   
//  ██████ ██  ██ ██ ██████ ██ █████  ████ 
//
// ------------------------------------------------------------------------------------------------------------------------
// URIList

	/**
	 * URIList
	 * @overview	A utility class to load, cache and filter lists of URIs
	 * @instance	uris
	 */

	xjsfl.init(this, ['Folder', 'URI', 'Utils']);
	
	// --------------------------------------------------------------------------------
	// Constructor

		/**
		 * URIList constructor
		 * @param	{String}	source		A valid folder path or URI (glob/wildcards allowed)
		 * @param	{Array}		source		A list of URIs
		 * @param	{Boolean}	recursive	An optional flag to search the folder recursively
		 */
		URIList = function(source, recursive)
		{
			// variables
				var uris	= [];
				var folderURI;
				
			// parse Array
				if(Utils.isArray(source))
				{
					uris = source;
				}
				
			// string
				else
				{
					// variables
						var uri = URI.toURI(source, 1);
						
					// test if wildcards
						if(uri.indexOf('*') !== -1)
						{
							uris = Utils.glob(uri);
						}
						
					// otherwise, just grab folder content
						else
						{
							var folderURI = new URI(uri).folder;
							FLfile.exists(folderURI)
							{
								if(recursive)
								{
									uris	= Utils.walkFolder(folderURI, true);
								}
								else
								{
									uris	= new Folder(folderURI).uris;
								}
							}
						}
				}
				
			// --------------------------------------------------------------------------------
			// # Properties
			
				/**
				 * @type {Number} Gets the length of the URIList
				 */
				this.__defineGetter__( 'length', function(){ return uris.length; } );
				
			// --------------------------------------------------------------------------------
			// # Methods
			
				/**
				 * Returns the full, or filtered list, of URIs
				 * @param		{String}	pattern		A wildcard (*) pattern
				 * @param		{RegExp}	pattern		A regular expression
				 * @param		{Boolean}	find		An optional Boolean to return the first URI found
				 * @returns		{URI}					A single URI, if find is passed as true
				 * @returns		{Array}					An Array of URI strings
				 */
				this.getURIs = function(pattern, find)
				{
					if(pattern)
					{
						return (find ? this.find(pattern) : this.filter(pattern));
					}
					else
					{
						return [].concat(uris);
					}
				}
				
				/**
				 * Returns the full, or filtered list, of paths
				 * @param		{String}	pattern		A wildcard (*) pattern
				 * @param		{RegExp}	pattern		A regular expression
				 * @param		{Boolean}	find		An optional Boolean to return the first URI found
				 * @returns		{URI}					A single URI, if find is passed as true
				 * @returns		{Array}					An Array of path strings
				 */
				this.getPaths = function(pattern, find)
				{
					var results = this.getURIs(pattern, find);
					if(find)
					{
						return results ? URI.asPath(results) : null;
					}
					else
					{
						for (var i = 0; i < results.length; i++)
						{
							results[i] = URI.asPath(results[i]);
						}
						return results;
					}
				}
				
				/**
				 * Filters the URIs according to a wildcard pattern or regular expression
				 * @param	{String}	pattern		A wildcard (*) pattern
				 * @param	{RegExp}	pattern		A regular expression
				 * @returns	{Array}					An Array of URIs
				 */
				this.filter = function(pattern)
				{
					var rx = pattern instanceof RegExp ? pattern : Utils.makeWildcard(pattern);
					return uris.filter(function(uri){ return rx.test(uri); });
				},
				
				/**
				 * Finds the first URI that matches a wildcard pattern or regular expression
				 * @param	{String}	pattern		A wildcard (*) pattern
				 * @param	{RegExp}	pattern		A regular expression
				 * @returns	{URI}					A single URI
				 */
				this.find = function(pattern)
				{
					var uri;
					var rx = pattern instanceof RegExp ? pattern : Utils.makeWildcard(pattern);
					for (var i = 0; i < uris.length; i++)
					{
						uri = uris[i];
						if(rx.test(uri))
						{
							return new URI(uri);
						}
					}
					return null;
				},
				
				/**
				 * Appends new URIs onto the existing list of URIs
				 * @param	{String}	source		A valid folder path or URI
				 * @param	{Array}		source		A list of URIs
				 * @param	{Boolean}	recursive	An optional flag to search the folder recursively
				 * @returns	{URIList}				The original URIList instance
				 */
				this.append = function(source, recursive)
				{
					var list = new URIList(source, recursive);
					uris = uris.concat(list.getURIs());
					return this;
				}
				
				/**
				 * Returns a new URIList based on the current filtered set
				 * @returns	{URIList}		A new URIList instance
				 */
				this.clone = function()
				{
					return new URIList(uris);
				}
				
				/**
				 * Returns a String representation of the URIList
				 * @returns	{String}		The String representation of the URIList
				 */
				this.toString = function()
				{
					return '[object URIList length=' +uris.length+ ']';
				}
		}

	// --------------------------------------------------------------------------------
	// Static properties

		URIList.toString = function()
		{
			return '[class URIList]';
		}

	// --------------------------------------------------------------------------------
	// Register class
	
		xjsfl.classes.register('URIList', URIList);


