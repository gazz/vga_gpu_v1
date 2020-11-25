def output_c(unpacked):
	print("// Outputting C array:\n");
	# print("Outputting C sprites");
	pass

def output_hex(unpacked):
	# print("// Outputting hex sprites:\n");
	for i in range(0, len(unpacked),  10):
		print("%x%x%x%x%x%x%x%x%x%x " 
			% (unpacked[i], 
				unpacked[i + 1],
				unpacked[i + 2],
				unpacked[i + 3],
				unpacked[i + 4],
				unpacked[i + 5],
				unpacked[i + 6],
				unpacked[i + 7],
				unpacked[i + 8],
				unpacked[i + 9]))
	pass


def main():
	# read input bytes & output them as hexvalues to be consumed by verilog compiler
	import argparse

	parser = argparse.ArgumentParser(
		description='Sprite format generator supports reads raw sprite file and can output either c-array(for C include) or hex-text(for verilog)')

	parser.add_argument(
		'spritefile',
		help='input raw sprite file to format')

	parser.add_argument(
		'format',
		choices=["c-array", "hex-text"],
		help='Output format')

	args = parser.parse_args()

	unpacked_bytes = []

	try:
		with open(args.spritefile, 'rb') as f:
			import struct
			byte = f.read(1)
			while byte:
				# u = struct.unpack('c', byte)[0]
				as_int = int.from_bytes(byte, byteorder='big')
				unpacked_bytes.append((as_int >> 4) & 0xf)
				unpacked_bytes.append(as_int & 0xf)
				byte = f.read(1)
	except FileNotFoundError as e:
		print("Can not open input file %s" % args.spritefile)
		parser.print_help();
		return

	# print("Unpacked: %s" % str(unpacked_bytes));


	if (args.format == "c-array"):
		output_c(unpacked_bytes)
	elif (args.format == "hex-text"):
		output_hex(unpacked_bytes)

	pass

if __name__ == '__main__':
	main()