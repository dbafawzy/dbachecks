$filename = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")

Describe "Database Collation" -Tags DatabaseCollation, $filename {
	(Get-SqlInstance).ForEach{
		Context "Testing database collation on $psitem" {
			(Test-DbaDatabaseCollation -SqlInstance $psitem).ForEach{
				It "database collation ($($psitem.DatabaseCollation)) should match server collation ($($psitem.ServerCollation)) for $($psitem.Database)" {
					$psitem.ServerCollation | Should Be $psitem.DatabaseCollation
				}
			}
		}
	}
}

Describe "Suspect Page" -Tags SuspectPage, $filename {
	(Get-SqlInstance).ForEach{
		Context "Testing suspect pages on $psitem" {
			(Get-DbaDatabase -SqlInstance $psitem).ForEach{
				$results = Get-DbaSuspectPage -SqlInstance $psitem.Parent -Database $psitem.Name
				It "$psitem should return 0 suspect pages" {
					$results.Count | Should Be 0
				}
			}
		}
	}
}

Describe "Last Backup Restore & Integrity Checks" -Tags TestLastBackup, Backup, $filename {
	$verifyonly = Get-DbcConfigValue policy.verifyonly
	$destserver = Get-DbcConfigValue policy.backuptestserver
	$destdata = Get-DbcConfigValue policy.backupdatadir
	$destlog = Get-DbcConfigValue policy.backuplogdir
	(Get-SqlInstance).ForEach{
		Context "Testing Backup Restore & Integrity Checks (VerifyOnly = $verifyonly) on $psitem" {
			(Test-DbaLastBackup -SqlInstance $psitem -Destination $destserver -LogDirectory $destlog -DataDirectory $destdata -VerifyOnly:$verifyonly).ForEach{
				if ($psitem.DBCCResult -notmatch 'skipped for restored master') {
					It "DBCC for $($psitem.Database) should be success" {
						$psitem.DBCCResult | Should Be 'Success'
					}
					It "restore for $($psitem.Database) should be success" {
						$psitem.RestoreResult | Should Be 'Success'
					}
				}
			}
		}
	}
}

Describe "Database Owners" -Tags DatabaseOwner, $filename {
	$targetowner = Get-DbcConfigValue policy.dbownershould
	(Get-SqlInstance).ForEach{
		Context "Testing Database Owners on $psitem" {
			(Test-DbaDatabaseOwner -SqlInstance $psitem -TargetLogin $targetowner).ForEach{
				It "$($psitem.Database) owner should be $targetowner" {
					$psitem.CurrentOwner | Should Be $psitem.TargetOwner
				}
			}
		}
	}
}

Describe "Not Database Owners" -Tags NotDatabaseOwner, $filename {
	$targetowner = Get-DbcConfigValue policy.dbownershouldnot
	(Get-SqlInstance).ForEach{
		Context "Testing Database Owners on $psitem" {
			(Test-DbaDatabaseOwner -SqlInstance $psitem -TargetLogin $targetowner).ForEach{
				It "$($psitem.Database) owner should Not be $targetowner" {
					$psitem.CurrentOwner | Should Not Be $psitem.TargetOwner
				}
			}
		}
	}
}

Describe "Last Good DBCC CHECKDB" -Tags LastGoodCheckDb, $filename {
	$maxdays = Get-DbcConfigValue policy.integritycheckmaxdays
	$datapurity = Get-DbcConfigValue skip.datapuritycheck
	(Get-SqlInstance).ForEach{
		Context "Testing Last Good DBCC CHECKDB on $psitem" {
			(Get-DbaLastGoodCheckDb -SqlInstance $psitem).ForEach{
				if ($psitem.Database -ne 'tempdb') {
					It "last good integrity check for $($psitem.Database) should be less than $maxdays" {
						$psitem.LastGoodCheckDb | Should BeGreaterThan (Get-Date).AddDays(- ($maxdays))
					}
					
					It -Skip:$datapurity "last good integrity check for $($psitem.Database) has Data Purity Enabled" {
						$psitem.DataPurityEnabled | Should Be $true
					}
				}
			}
		}
	}
}

Describe "Column Identity Usage" -Tags IdentityUsage, $filename {
	$maxpercentage = Get-DbcConfigValue policy.identityusagepercent
	(Get-SqlInstance).ForEach{
		Context "Testing Column Identity Usage on $psitem" {
			(Test-DbaIdentityUsage -SqlInstance $psitem).ForEach{
				if ($psitem.Database -ne 'tempdb') {
					$columnfqdn = "$($psitem.Database).$($psitem.Schema).$($psitem.Table).$($psitem.Column)"
					It "usage for $columnfqdn should be less than $maxpercentage percent" {
						$psitem.PercentUsed -lt $maxpercentage | Should be $true
					}
				}
			}
		}
	}
}

Describe "Recovery Model" -Tags RecoveryModel, DISA, $filename {
	(Get-SqlInstance).ForEach{
		Context "Testing Recovery Model on $psitem" {
			(Get-DbaDbRecoveryModel -SqlInstance $psitem -ExcludeDatabase tempdb).ForEach{
				It "$($psitem.Name) should be set to $((Get-DbcConfigValue policy.recoverymodel))" {
					$psitem.RecoveryModel | Should be (Get-DbcConfigValue policy.recoverymodel)
				}
			}
		}
	}
}

Describe "Duplicate Index" -Tags DuplicateIndex, $filename {
	(Get-SqlInstance).ForEach{
		Context "Testing duplicate indexes on $psitem" {
			(Get-DbaDatabase -SqlInstance $psitem).ForEach{
				It "$psitem should not have duplicate indexes" {
					Find-SqlDuplicateIndex -SqlInstance $psitem.Parent -Database $psitem.Name | Should Be $null
				}
			}
		}
	}
}

Describe "Page Verify" -Tags PageVerify, $filename {
	$pageverify = Get-DbcConfigValue policy.pageverify
	(Get-SqlInstance).ForEach{
		Context "Testing page verify on $psitem" {
			(Get-DbaDatabase -SqlInstance $psitem).ForEach{
				It "$psitem should has page verify set to $pageverify" {
					(Get-DbaDatabase -SqlInstance $psitem.Parent -Database $psitem.Name).PageVerify | Should Be $pageverify
				}
			}
		}
	}
}

Describe "Auto Close" -Tags AutoClose, $filename {
	$autoclose = Get-DbcConfigValue policy.autoclose
	(Get-SqlInstance).ForEach{
		Context "Testing Auto Close on $psitem" {
			(Get-DbaDatabase -SqlInstance $psitem).ForEach{
				It "$psitem should has Auto Close set to $autoclose" {
					(Get-DbaDatabase -SqlInstance $psitem.Parent -Database $psitem.Name).AutoClose | Should Be $autoclose
				}
			}
		}
	}
}

Describe "Auto Shrink" -Tags AutoShrink, $filename {
	$autoshrink = Get-DbcConfigValue policy.autoshrink
	(Get-SqlInstance).ForEach{
		Context "Testing Auto Shrink on $psitem" {
			(Get-DbaDatabase -SqlInstance $psitem).ForEach{
				It "$psitem should has Auto Shrink set to $autoshrink" {
					(Get-DbaDatabase -SqlInstance $psitem.Parent -Database $psitem.Name).AutoShrink | Should Be $autoshrink
				}
			}
		}
	}
}

Describe "Last Full Backup Times" -Tags LastFullBackup, LastBackup, Backup, DISA, $filename {
	$maxfull = Get-DbcConfigValue policy.backupfullmaxdays
	(Get-SqlInstance).ForEach{
		Context "Testing last full backups on $psitem" {
			(Get-DbaDatabase -SqlInstance $psitem -ExcludeDatabase tempdb).ForEach{
				It "$($psitem.Name) full backups should be less than $maxfull days" {
					$psitem.LastFullBackup | Should BeGreaterThan (Get-Date).AddDays(-($maxfull))
				}
			}
		}
	}
}

Describe "Last Diff Backup Times" -Tags LastDiffBackup, LastBackup, Backup, DISA, $filename {
	$maxdiff = Get-DbcConfigValue policy.backupdiffmaxhours
	(Get-SqlInstance).ForEach{
		Context "Testing last diff backups on $psitem" {
			(Get-DbaDatabase -SqlInstance $psitem | Where {-not $psitem.IsSystemObject}).ForEach{
				It "$($psitem.Name) diff backups should be less than $maxdiff hours" {
					$psitem.LastDiffBackup | Should BeGreaterThan (Get-Date).AddHours(-($maxdiff))
				}
			}
		}
	}
}

Describe "Last Log Backup Times" -Tags LastLogBackup, LastBackup, Backup, DISA, $filename {
	$maxlog = Get-DbcConfigValue policy.backuplogmaxminutes
	(Get-SqlInstance).ForEach{
		Context "Testing last log backups on $psitem" {
			(Get-DbaDatabase -SqlInstance $psitem | Where-Object { -not $psitem.IsSystemObject }).ForEach{
				if ($psitem.RecoveryModel -ne 'Simple') {
					It "$($psitem.Name) log backups should be less than $maxlog minutes" {
						$psitem.LastLogBackup | Should BeGreaterThan (Get-Date).AddMinutes(-($maxlog)+1)
					}
				}
				
			}
		}
	}
}