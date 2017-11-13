function Locs = parseLocationData(importedValue)

		Locs = zeros(size(importedValue, 1), 11);
        Locs(:, 1) = vertcat(importedValue.ID);
        Locs(:, 2) = vertcat(importedValue.ParentID);
        Locs(:, 3) = vertcat(importedValue.VolumeX);
        Locs(:, 4) = vertcat(importedValue.VolumeY);
        Locs(:, 5) = vertcat(importedValue.Z);
        Locs(:, 6) = vertcat(importedValue.Radius);
        Locs(:, 7) = vertcat(importedValue.X);
        Locs(:, 8) = vertcat(importedValue.Y);
        Locs(:, 9) = vertcat(importedValue.OffEdge);
        Locs(:, 10) = vertcat(importedValue.Terminal);
        Locs(:, 11) = vertcat(importedValue.TypeCode);