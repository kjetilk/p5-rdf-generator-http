use Test::Perl::Critic(-exclude => [
												'RequireFinalReturn',
											   'ProhibitUnusedPrivateSubroutines',
												'ProhibitHardTabs'
											  ],
							  -severity => 3);
all_critic_ok();
