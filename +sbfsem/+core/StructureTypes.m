classdef StructureTypes
	
	enumeration
		Cell
		GapJunction
		ConvPre
		ConvPost
		RibbonPre
		RibbonPost
		BipConvPre
		BipConvPost
		GABAPre
		GABAPost
		Desmosome
		BasalTA
		BasalNTA
		BasalMNTA
		Touch
        CisternPre
        CisternPost
        PlaqueLikePre
        PlaqueLikePost
		INLIPLBoundary
		IPLGCLBoundary
		Unknown
		AnnularGapJunction
		Axon
		Caveola
		CHBoundary
		Cilium
		Endocytosis
		GolgiPlaque
		GolgiNormal
		Loop
		Lysosome
		Mitochondria
		MultivesicularBody
		NuclearFilament
		Nucleolus
		NeuroglialAdherens
		OrganizedSER
		Plaque
		Polysomes
		RibbonCluster
		RibosomePatch
		Rootlet
		VesselAdjacency
	end

	methods
		function rgb = StructureColor(obj)
			import sbfsem.core.StructureTypes;

			switch obj
				case StructureTypes.Cell
					rgb = [0.2, 0.2, 0.2]; 
				case StructureTypes.ConvPre
					rgb = [1, 0.278, 0.298];
				case StructureTypes.ConvPost
					rgb = [0.992, 0.667, 0.282];
				case StructureTypes.RibbonPre
					rgb = [0.082, 0.69, 0.102];
				case StructureTypes.RibbonPost
					rgb = [0.2501, 0.639, 0.408];
				case StructureTypes.BipConvPre
					rgb = [0.024, 0.322, 1];
				case StructureTypes.BipConvPost
					rgb = [0.016, 0.847, 0.698];
				case StructureTypes.GABAPre
					rgb = [0.780, 0.376, 1];
				case StructureTypes.GABAPost
					rgb = [0.780, 0.376, 1];
				case StructureTypes.BasalTA
					rgb = [1 0.278 0.298];
				case StructureTypes.BasalNTA 
					rgb = [0.518, 0, 0];
				case StructureTypes.BasalMNTA
					rgb = [0.518, 0, 0];
				case StructureTypes.GapJunction
					rgb = [0.58 0.824 0.988];
				case StructureTypes.Desmosome
					rgb = [0.024, 0.604, 0.953];
				case StructureTypes.Touch
					rgb = [0.075, 0.918, 0.788];
				case StructureTypes.Endocytosis
					rgb = [0.565, 0.894, 0.757];
				case StructureTypes.Unknown
					rgb = [0.5 0.5 0.5];
				otherwise
					rgb = [0, 0, 0];
			end
		end

		function ret = isPre(obj)
			import sbfsem.core.StructureTypes;

			if ismember(obj,...
				[StructureTypes.GABAPre,...
				StructureTypes.RibbonPre,...
				StructureTypes.BipConvPre,...
				StructureTypes.ConvPre])
				ret = true;
			else
				ret = false;
			end
		end

		function tf = isPost(obj)
			import sbfsem.core.StructureTypes;

			if ismember(obj,...
				[StructureTypes.GABAPost,...
				StructureTypes.RibbonPost,...
				StructureTypes.BipConvPost,...
				StructureTypes.ConvPost,...
				StructureTypes.BasalTA,...
				StructureTypes.BasalNTA,...
				StructureTypes.BasalMNTA])
				tf = true;
			else
				tf = false;
			end
		end

		function tf = isUndirected(obj)
			import sbfsem.core.StructureTypes;

			if ismember(obj,...
				[StructureTypes.Unknown,...
				StructureTypes.GapJunction,...
				StructureTypes.Desmosome,...
				StructureTypes.Touch])
				tf = true;
		    else
		    	tf = false;
			end 
		end

		function tf = isSynapse(obj)
			if ismember(obj,...
				[StructureTypes.Cell,...
				StructureTypes.Endocytosis,...
				StructureTypes.INLIPLBoundary,...
				StructureTypes.IPLGCLBoundary,...
                StructureTypes.CHBoundary,...
				StructureTypes.Cilium,...
				StructureTypes.Plaque,...
                StructureTypes.MultivesicularBody,...
                StructureTypes.RibosomePatch])
				tf = false;
			else
				tf = true;
			end
        end
        
        function tf = isBoundaryMarker(obj)
            if ismember(obj,...
                [StructureTypes.CHBoundary,...
                StructureTypes.INLIPLBoundary,...
                StructureTypes.GCLIPLBoundary])
                tf = true;
            else
                tf = false;
            end
        end
	end

	methods (Static)
		function obj = fromViking(vikingStructure, tags)
			% FROMVIKING  Convert VikingStructureType to StructureType
			assert(isa(vikingStructure, 'sbfsem.core.VikingStructureTypes'),...
				'Input a Viking Structure Type');

			import sbfsem.core.VikingStructureTypes;
			import sbfsem.core.StructureTypes;

			if nargin < 2 || isempty(tags)
				tags = '';
			end

			switch vikingStructure
                case VikingStructureTypes.Cell % 1
                    obj = StructureTypes.Cell;
				case VikingStructureTypes.Conventional % 34
					if strcmp(tags, 'GABA')
						obj = StructureTypes.GABAPre;
					else
						obj = StructureTypes.ConvPre;
					end
				case VikingStructureTypes.Postsynapse % 35
					switch tags
						case {'Conventional;GABA', 'GABA'}
							obj = StructureTypes.GABAPost;
						case {'Bipolar;Ribbon;Glutamate', 'Ribbon', 'Ribbon;Glutamate'}
							obj = StructureTypes.RibbonPost;
						case 'Bipolar;Conventional;Glutamate'
							obj = StructureTypes.BipConvPost;
						case 'Conventional;TA'
							obj = StructureTypes.BasalTA;
						case 'Conventional;NTA'
							obj = StructureTypes.BasalNTA;
						case 'Conventional;mNTA'
							obj = StructureTypes.BasalMNTA;
						otherwise
							obj = StructureTypes.ConvPost;
					end
				case VikingStructureTypes.Adherens
					obj = StructureTypes.Desmosome;
				case VikingStructureTypes.BCConventionalSynapse
					obj = StructureTypes.BipConvPre;
				case VikingStructureTypes.RibbonSynapse
					obj = StructureTypes.RibbonPre;
				case VikingStructureTypes.Touch
					obj = StructureTypes.Touch;
				case VikingStructureTypes.GapJunction
					obj = StructureTypes.GapJunction;
                case VikingStructureTypes.PlaqueLikePre
                    obj = StructureTypes.PlaqueLikePre;
                case VikingStructureTypes.PlaqueLikePost
                    obj = StructureTypes.PlaqueLikePost;
				case VikingStructureTypes.CisternPre
					obj = StructureTypes.CisternPre;
				case VikingStructureTypes.CisternPost
					obj = StructureTypes.CisternPost;
                case VikingStructureTypes.AnnularGapJunction
                    obj = StructureTypes.AnnularGapJunction;
                case VikingStructureTypes.Axon
                    obj = StructureTypes.Axon;
                case VikingStructureTypes.Caveola
                    obj = StructureTypes.Caveola;
                case VikingStructureTypes.CHBoundary
                    obj = StructureTypes.CHBoundary;
				case VikingStructureTypes.Cilium
					obj = StructureTypes.Cilium;
                case VikingStructureTypes.Endocytosis
					obj = StructureTypes.Endocytosis;
                case VikingStructureTypes.GolgiPlaque
                    obj = StructureTypes.GolgiPlaque;
                case VikingStructureTypes.GolgiNormal
                    obj = StructureTypes.GolgiNormal;
                case VikingStructureTypes.Loop
                    obj = StructureTypes.Loop;
                case VikingStructureTypes.Lysosome
                    obj = StructureTypes.Lysosome;
                case VikingStructureTypes.Mitochondria
                    obj = StructureTypes.Mitochondria;
                case VikingStructureTypes.MultivesicularBody
                    obj = StructureTypes.MultivesicularBody;
                case VikingStructureTypes.NuclearFilament
                    obj = StructureTypes.NuclearFilament;
                case VikingStructureTypes.Nucleolus
                    obj = StructureTypes.Nucleolus;
                case VikingStructureTypes.NeuroglialAdherens
                    obj = StructureTypes.NeuroglialAdherens;
                case VikingStructureTypes.OrganizedSER
                    obj = StructureTypes.OrganizedSER;
				case VikingStructureTypes.Plaque
					obj = StructureTypes.Plaque;
                case VikingStructureTypes.Polysomes
                    obj = StructureTypes.Polysomes;
                case VikingStructureTypes.RibbonCluster
                    obj = StructureTypes.RibbonCluster;
                case VikingStructureTypes.RibosomePatch
                    obj = StructureTypes.RibosomePatch;
                case VikingStructureTypes.Rootlet
                    obj = StructureTypes.Rootlet;
				case VikingStructureTypes.Unknown
					obj = StructureTypes.Unknown;
                case VikingStructureTypes.VesselAdjacency
                    obj = StructureTypes.VesselAdjacency;
			end
		end
	end
end

