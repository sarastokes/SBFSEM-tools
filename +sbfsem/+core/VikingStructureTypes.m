classdef VikingStructureTypes < double
	
	enumeration
		Cell (1)
		Vessel (3)
		GapJunction (28)
		Bipolar (31)
		Conventional (34)
		Postsynapse (35)
		RibbonSynapse (73)
		Test (80)
		OrganizedSER (81)
		Adherens (85)
		CisternPre (181)
		CisternPost (182)
		Cilium (183)
		BCConventionalSynapse (189)
		Multicistern (219)
		Endocytosis (220)
		INLIPLBoundary (224)
		MultivesicularBody (225)
		RibosomePatch (226)
		RibbonCluster (227)
		Touch (229)
		Loop (230)
		Polysomes (232)
		Depth (233)
		Marker (234)
		IPLGCLBoundary (235)
		Plaque (236)
		Axon (237)
		PlaqueLikePre (240)
		PlaqueLikePost (241)
		NeuroglialAdherens (243)
		Unknown (244)
		Nucleolus (245)
		Mitochondria (246)
		Caveola (247)
		NuclearFilament (248)
		GolgiPlaque (249)
		GolgiNormal (250)
		Lysosome (252)
		AnnularGapJunction (253)
		VesselAdjacency (254)
		Rootlet (255)
		CHBoundary (256)
	end

	methods
		function str = localName(obj, tag)
            % LOCALNAME  Returns the sbfsem-tools name
            import sbfsem.core.StructureTypes;
            
			if nargin < 2
				tag = '';
			else
				tag = lower(tag);
			end

			switch obj
				case StructureTypes.Conventional % 34
					if strcmp(tag, 'gaba')
						str = 'GABAPre';
					else
						str = 'ConvPre';
					end
				case StructureTypes.Postsynapse % 35
					switch tag
						case 'gaba'
							str = 'GABAPost';
						case 'bipolar;ribbon;glutamate'
							str= 'RibbonPost';
						case 'bipolar;conventional;glutamate'
							str = 'BipConvPost';
						case 'conventional;ta'
							str = 'BasalTA';
						case 'conventional;nta'
							str = 'BasalNTA';
						case 'conventional;mnta'
							str = 'BasalMNTA';
						otherwise
							str = 'ConvPost';
					end
				case StructureTypes.RibbonSynapse % 73
					str = 'RibbonPre';
				case StructureTypes.Adherens
					str = 'Desmosome';
				case StructureTypes.BCConventionalSynapse %189
					str = 'BipConvPre';
				case StructureTypes.INLIPLBoundary %224
					str = 'INLBoundary';
				case StructureTypes.IPLGCLBoundary
					str = 'GCLBoundary';
				case StructureTypes.PlaqueLikePre
					str = 'GABAPre';
				case StructureTypes.PlaqueLikePost
					str = 'GABAPost';
				otherwise
					str = char(obj);
			end
		end
	end
end

