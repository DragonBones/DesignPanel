package core.utils{

import flash.display.BitmapData;
import flash.utils.ByteArray;

/**
 *  The PNGEncoder class converts raw bitmap images into encoded
 *  images using Portable Network Graphics (PNG) lossless compression.
 *
 *  <p>For the PNG specification, see http://www.w3.org/TR/PNG/</p>.
 *  
 *  @langversion 3.0
 *  @playerversion Flash 9
 *  @playerversion AIR 1.1
 *  @productversion Flex 3
 */
public class PNGEncoder
{

	//--------------------------------------------------------------------------
	//
	//  Class constants
	//
	//--------------------------------------------------------------------------

    /**
     *  @private
	 *  The MIME type for a PNG image.
     */
    private static const CONTENT_TYPE:String = "image/png";

	//--------------------------------------------------------------------------
	//
	//  Constructor
	//
	//--------------------------------------------------------------------------

    /**
     *  Constructor.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 9
     *  @playerversion AIR 1.1
     *  @productversion Flex 3
     */
	initializeCRCTable();

	//--------------------------------------------------------------------------
	//
	//  Variables
	//
	//--------------------------------------------------------------------------

    /**
     *  @private
	 *  Used for computing the cyclic redundancy checksum
	 *  at the end of each chunk.
     */
    private static var crcTable:Array;
    
	//--------------------------------------------------------------------------
	//
	//  Properties
	//
	//--------------------------------------------------------------------------

	//----------------------------------
	//  contentType
	//----------------------------------

    /**
     *  The MIME type for the PNG encoded image.
     *  The value is <code>"image/png"</code>.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 9
     *  @playerversion AIR 1.1
     *  @productversion Flex 3
     */
    public static function get contentType():String
    {
        return CONTENT_TYPE;
    }

	//--------------------------------------------------------------------------
	//
	//  Methods
	//
	//--------------------------------------------------------------------------

    /**
     *  Converts the pixels of a BitmapData object
	 *  to a PNG-encoded ByteArray object.
     *
     *  @param bitmapData The input BitmapData object.
     *
     *  @return Returns a ByteArray object containing PNG-encoded image data.
     *  
     *  @langversion 3.0
     *  @playerversion Flash 9
     *  @playerversion AIR 1.1
     *  @productversion Flex 3
     */
    public static function encode(bitmapData:BitmapData):ByteArray
    {
        return internalEncode(bitmapData, bitmapData.width, bitmapData.height,
							  bitmapData.transparent);
    }

    /**
     *  Converts a ByteArray object containing raw pixels
	 *  in 32-bit ARGB (Alpha, Red, Green, Blue) format
	 *  to a new PNG-encoded ByteArray object.
	 *  The original ByteArray is left unchanged.
     *
     *  @param byteArray The input ByteArray object containing raw pixels.
	 *  This ByteArray should contain
	 *  <code>4 * width * height</code> bytes.
	 *  Each pixel is represented by 4 bytes, in the order ARGB.
	 *  The first four bytes represent the top-left pixel of the image.
	 *  The next four bytes represent the pixel to its right, etc.
	 *  Each row follows the previous one without any padding.
     *
     *  @param width The width of the input image, in pixels.
     *
     *  @param height The height of the input image, in pixels.
     *
     *  @param transparent If <code>false</code>, alpha channel information
	 *  is ignored but you still must represent each pixel 
     *  as four bytes in ARGB format.
     *
     *  @return Returns a ByteArray object containing PNG-encoded image data. 
     *  
     *  @langversion 3.0
     *  @playerversion Flash 9
     *  @playerversion AIR 1.1
     *  @productversion Flex 3
     */
    public static function encodeByteArray(byteArray:ByteArray, width:int, height:int,
									transparent:Boolean = true):ByteArray
    {
        return internalEncode(byteArray, width, height, transparent);
    }

    /**
	 *  @private
	 */
	private static function initializeCRCTable():void
	{
        crcTable = [];

        for (var n:uint = 0; n < 256; n++)
        {
            var c:uint = n;
            for (var k:uint = 0; k < 8; k++)
            {
                if (c & 1)
                    c = uint(uint(0xedb88320) ^ uint(c >>> 1));
				else
                    c = uint(c >>> 1);
             }
            crcTable[n] = c;
        }
	}

    /**
	 *  @private
	 */
	private static function internalEncode(
		source:Object,
		width:int,
		height:int,
		transparent:Boolean = true
	):ByteArray{
     	// The source is either a BitmapData or a ByteArray.
		var sourceByteArray:ByteArray;
		if(source is BitmapData){
			sourceByteArray = (source as BitmapData).getPixels((source as BitmapData).rect);
		}else{
			sourceByteArray = source as ByteArray;
		}
    	
        // Create output byte array
        var png:ByteArray = new ByteArray();

        // Write PNG signature
        png[0]=0x89;
		png[1]=0x50;
		png[2]=0x4E;
		png[3]=0x47;
		png[4]=0x0D;
		png[5]=0x0A;
		png[6]=0x1A;
		png[7]=0x0A;

        // Build IHDR chunk
        var IHDR:ByteArray = new ByteArray();
		IHDR[0]=width>>24;
		IHDR[1]=width>>16;
		IHDR[2]=width>>8;
		IHDR[3]=width;
		IHDR[4]=height>>24;
		IHDR[5]=height>>16;
		IHDR[6]=height>>8;
		IHDR[7]=height;
		IHDR[8]=8; // bit depth per channel
		IHDR[9]=6; // color type: RGBA
		IHDR[10]=0; // compression method
		IHDR[11]=0; // filter method
		IHDR[12]=0; // interlace method
        writeChunk(png, 0x49484452, IHDR);

        // Build IDAT chunk
        var IDAT:ByteArray = new ByteArray();
		var x:int,y:int;
		var offset:int=0;
		var sourceOffset:int=0;
		if(transparent){
			for (y = 0; y < height; y++){
				IDAT[offset++]=0; // no filter
				for (x = 0; x < width; x++){
					IDAT[offset++]=sourceByteArray[sourceOffset+1];
					IDAT[offset++]=sourceByteArray[sourceOffset+2];
					IDAT[offset++]=sourceByteArray[sourceOffset+3];
					IDAT[offset++]=sourceByteArray[sourceOffset];
					sourceOffset+=4;
				}
			}
		}else{
			for (y = 0; y < height; y++){
				IDAT[offset++]=0; // no filter
				for (x = 0; x < width; x++){
					IDAT[offset++]=sourceByteArray[sourceOffset+1];
					IDAT[offset++]=sourceByteArray[sourceOffset+2];
					IDAT[offset++]=sourceByteArray[sourceOffset+3];
					IDAT[offset++]=0xff;
					sourceOffset+=4;
				}
			}
		}
        
        IDAT.compress();
        writeChunk(png, 0x49444154, IDAT);

        // Build IEND chunk
        writeChunk(png, 0x49454E44, null);

        // return PNG
        return png;
    }

    /**
	 *  @private
	 */
	private static function writeChunk(png:ByteArray, type:int, data:ByteArray):void
    {
        // Write length of data.
        
		var offset:int=png.length;
		if (data){
			var len:int = data.length;
			png[offset++]=len>>24;
			png[offset++]=len>>16;
			png[offset++]=len>>8;
			png[offset++]=len;
		}else{
			png[offset++]=0;
			png[offset++]=0;
			png[offset++]=0;
			png[offset++]=0;
		}
        
		// Write chunk type.
		var typePos:int = offset;
		png[offset++]=type>>24;
		png[offset++]=type>>16;
		png[offset++]=type>>8;
		png[offset++]=type;
        
		// Write data.
		if (data){
            png.position=offset;
			png.writeBytes(data);
			offset=png.length;
		}

        // Write CRC of chunk type and data.
		var crcPos:int = offset;
        offset = typePos;
        var crc:uint = 0xFFFFFFFF;
		
		var i:int=crcPos-typePos;
        while(--i>=0){
            crc = crcTable[(crc ^ png[offset++]) & 0xFF] ^ (crc >>> 8);
        }
        crc = crc ^ 0xFFFFFFFF;
        offset = crcPos;
		png[offset++]=crc>>24;
		png[offset++]=crc>>16;
		png[offset++]=crc>>8;
		png[offset++]=crc;
    }
}

}
