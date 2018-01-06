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
		Endocytosis
		Unknown
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
			else
				% tags = lower(tags);
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
						case 'GABA'
							obj = StructureTypes.GABAPost;
						case 'Bipolar;Ribbon;Glutamate'
							obj = StructureTypes.RibbonPost;
						case 'Bipolar;Conventional;Glutamate'
							obj = StructureTypes.BipConvPost;
						case 'Conventional;TA'
							obj = StructureTypes.BasalTA;
						case 'Conventional;NTA'
							obj = StructureTypes.BasalNTA;
						case 'Conventional;MNTA'
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
				case VikingStructureTypes.CisternPost;
					obj = StructureTypes.Unknown;
				case VikingStructureTypes.Endocytosis
					obj = StructureTypes.Endocytosis;
				case VikingStructureTypes.Unknown
					obj = StructureTypes.Unknown;
			end
		end
	end
end

