#!/usr/bin/python
import argparse,sys,math,arc

##########################################################################
##########################################################################

def save_file(data,path):
    if path is not None:
        with open(path,'wb') as f:
            f.write(''.join([chr(x) for x in data]))

##########################################################################
##########################################################################

def main(options):
    # Only support MODE 9 for now. MODE 13 coming later.
    if options.mode == 9:
        pixels_per_byte=2
        pack=arc.pack_4bpp
        pixel_max=options.pixel_max or 16
    elif options.mode == 13:
        pixels_per_byte=1
        pack=arc.pack_8bpp
        pixel_max=options.pixel_max or 256
    else:
        print>>sys.stderr,'FATAL: invalid mode: %d'%options.mode
        sys.exit(1)

    width=options.xor_size
    height=options.xor_size
    print 'Image width: {0} height: {1}'.format(width,height)

    pixel_data=[]
    for y in range(0, height):
        for x in range(0,width,pixels_per_byte):
            xs=[]
            for p in range(0,pixels_per_byte):
                c = (pixel_max * (x+p) / width) ^ (pixel_max * y / height)
                if pixels_per_byte == 1 and pixel_max == 16:
                    c = c | (c << 4)
                xs.append(c)
            assert len(xs)==pixels_per_byte
            pixel_data.append(pack(xs))

    assert(len(pixel_data)==width*height/pixels_per_byte)
    save_file(pixel_data,options.output_path)
    print 'Wrote {0} bytes Arc data.'.format(len(pixel_data))


##########################################################################
##########################################################################

if __name__=='__main__':
    parser=argparse.ArgumentParser()

    parser.add_argument('-o',dest='output_path',metavar='FILE',help='output ARC data to %(metavar)s')
    parser.add_argument('--pixel_max',type=int,help='max pixel value')
    parser.add_argument('mode',type=int,help='screen mode')
    parser.add_argument('xor_size',type=int,help='size of the texture')
    main(parser.parse_args())
