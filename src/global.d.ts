interface Navigator {
	userAgentData?: {
		platform: string;
		mobile: boolean;
		brands: { brand: string; version: string }[];
		getHighEntropyValues(hints: string[]): Promise<any>;
	};
}
